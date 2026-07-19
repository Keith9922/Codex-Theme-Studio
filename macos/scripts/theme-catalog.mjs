#!/usr/bin/env node

import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { execFile, execFileSync } from "node:child_process";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

const execFileAsync = promisify(execFile);
const scriptsRoot = path.dirname(fileURLToPath(import.meta.url));
const engineRoot = path.resolve(scriptsRoot, "..");
const bundledRoot = path.join(engineRoot, "presets");
const defaultLibraryRoot = path.join(
  os.homedir(),
  "Library",
  "Application Support",
  "CodexDreamSkinStudio",
  "themes",
);
const safeID = /^[A-Za-z0-9_-]{1,80}$/;
const safeAsset = /^[^/\\\0]{1,180}$/;

function fail(message) {
  throw new Error(message);
}

function parseArguments(argv) {
  const [command = "list", ...rest] = argv;
  const options = {};
  for (let index = 0; index < rest.length; index += 1) {
    const token = rest[index];
    if (!token.startsWith("--")) fail(`未知参数：${token}`);
    const key = token.slice(2);
    if (["json", "apply", "install", "force"].includes(key)) {
      options[key] = true;
      continue;
    }
    const value = rest[index + 1];
    if (!value || value.startsWith("--")) fail(`参数 --${key} 缺少值`);
    options[key] = value;
    index += 1;
  }
  return { command, options };
}

function assertThemeID(value) {
  if (!safeID.test(value ?? "")) fail("主题 id 只能包含字母、数字、连字符和下划线，且不超过 80 字符。");
  return value;
}

function assertColor(value, label) {
  if (!/^#[0-9A-Fa-f]{6}$/.test(value ?? "")) fail(`${label} 必须是 #RRGGBB 色值。`);
  return value.toUpperCase();
}

async function isDirectory(value) {
  try {
    return (await fs.lstat(value)).isDirectory();
  } catch {
    return false;
  }
}

async function inspectPack(directory, source) {
  if (!(await isDirectory(directory))) return null;
  const stat = await fs.lstat(directory);
  if (stat.isSymbolicLink()) return null;

  let theme;
  try {
    theme = JSON.parse(await fs.readFile(path.join(directory, "theme.json"), "utf8"));
  } catch {
    return null;
  }
  const id = path.basename(directory);
  if (!safeID.test(id) || theme.id !== id || !safeAsset.test(theme.image ?? "")) return null;
  const imagePath = path.join(directory, theme.image);
  try {
    const imageStat = await fs.lstat(imagePath);
    if (!imageStat.isFile() || imageStat.isSymbolicLink()) return null;
  } catch {
    return null;
  }

  const catalog = theme.catalog && typeof theme.catalog === "object" ? theme.catalog : {};
  return {
    id,
    name: typeof theme.name === "string" && theme.name.trim() ? theme.name.trim() : id,
    category: typeof catalog.category === "string" ? catalog.category : id.startsWith("custom-") || id.startsWith("img-") ? "custom" : "other",
    description: typeof catalog.description === "string" ? catalog.description : typeof theme.tagline === "string" ? theme.tagline : "",
    tags: Array.isArray(catalog.tags) ? catalog.tags.filter((tag) => typeof tag === "string") : [],
    featured: catalog.featured === true,
    source,
    directory,
    image: imagePath,
  };
}

async function scanRoot(root, source) {
  if (!(await isDirectory(root))) return [];
  const entries = await fs.readdir(root, { withFileTypes: true });
  const packs = await Promise.all(
    entries
      .filter((entry) => entry.isDirectory() && !entry.name.startsWith("."))
      .map((entry) => inspectPack(path.join(root, entry.name), source)),
  );
  return packs.filter(Boolean);
}

async function catalog(libraryRoot) {
  const [installed, bundled] = await Promise.all([
    scanRoot(libraryRoot, "installed"),
    scanRoot(bundledRoot, "bundled"),
  ]);
  const result = new Map();
  for (const pack of bundled) result.set(pack.id, pack);
  for (const pack of installed) result.set(pack.id, pack);
  return [...result.values()].sort((left, right) => {
    if (left.featured !== right.featured) return left.featured ? -1 : 1;
    return left.name.localeCompare(right.name, "zh-Hans-CN");
  });
}

function searchableText(theme) {
  return [theme.id, theme.name, theme.category, theme.description, ...theme.tags]
    .join(" ")
    .toLocaleLowerCase("zh-Hans-CN");
}

function publicTheme(theme, installedIDs) {
  return {
    id: theme.id,
    name: theme.name,
    category: theme.category,
    description: theme.description,
    tags: theme.tags,
    featured: theme.featured,
    installed: installedIDs.has(theme.id),
    source: theme.source,
    directory: theme.directory,
  };
}

function printThemes(themes, json) {
  if (json) {
    process.stdout.write(`${JSON.stringify(themes, null, 2)}\n`);
    return;
  }
  if (!themes.length) {
    process.stdout.write("没有找到匹配的主题。\n");
    return;
  }
  for (const theme of themes) {
    const marker = theme.installed ? "已安装" : "可安装";
    process.stdout.write(`${theme.id.padEnd(28)} ${marker.padEnd(6)} ${theme.name} · ${theme.description}\n`);
  }
}

async function validatePack(directory) {
  const injector = path.join(scriptsRoot, "injector.mjs");
  const { stdout } = await execFileAsync(process.execPath, [
    injector,
    "--check-payload",
    "--theme-dir",
    directory,
  ]);
  const result = JSON.parse(stdout);
  if (!result.pass) fail("主题包未通过注入前校验。");
}

async function copyPackAtomically(source, libraryRoot, force) {
  const pack = await inspectPack(source, "source");
  if (!pack) fail(`不是有效的 Codex Theme Studio 主题包：${source}`);
  await validatePack(source);
  await fs.mkdir(libraryRoot, { recursive: true, mode: 0o700 });
  const destination = path.join(libraryRoot, pack.id);
  const temporary = path.join(libraryRoot, `.install-${pack.id}-${process.pid}-${Date.now()}`);

  try {
    await fs.mkdir(temporary, { mode: 0o700 });
    for (const entry of await fs.readdir(source, { withFileTypes: true })) {
      if (!entry.isFile()) continue;
      const sourceFile = path.join(source, entry.name);
      const stat = await fs.lstat(sourceFile);
      if (stat.isSymbolicLink()) fail(`主题包不允许符号链接：${entry.name}`);
      await fs.copyFile(sourceFile, path.join(temporary, entry.name));
    }
    await validatePack(temporary);
    if (await isDirectory(destination)) {
      if (!force && !pack.id.startsWith("preset-")) fail(`主题已存在：${pack.id}。如需覆盖请添加 --force。`);
      await fs.rm(destination, { recursive: true, force: true });
    }
    await fs.rename(temporary, destination);
    return { ...pack, directory: destination, image: path.join(destination, path.basename(pack.image)) };
  } finally {
    await fs.rm(temporary, { recursive: true, force: true });
  }
}

function toRGB(value) {
  return [
    Number.parseInt(value.slice(1, 3), 16),
    Number.parseInt(value.slice(3, 5), 16),
    Number.parseInt(value.slice(5, 7), 16),
  ];
}

async function writeSolidArtwork(destination, primary, secondary) {
  const width = 1920;
  const height = 1200;
  const start = toRGB(primary);
  const end = toRGB(secondary);
  const header = Buffer.from(`P6\n${width} ${height}\n255\n`);
  const pixels = Buffer.alloc(width * height * 3);
  for (let y = 0; y < height; y += 1) {
    const vertical = y / (height - 1);
    for (let x = 0; x < width; x += 1) {
      const t = Math.min(1, x / (width - 1) * 0.22 + vertical * 0.78);
      const index = (y * width + x) * 3;
      for (let channel = 0; channel < 3; channel += 1) {
        pixels[index + channel] = Math.round(start[channel] + (end[channel] - start[channel]) * t);
      }
    }
  }
  const ppm = `${destination}.ppm`;
  await fs.writeFile(ppm, Buffer.concat([header, pixels]), { mode: 0o600 });
  try {
    execFileSync(
      "/usr/bin/sips",
      ["-s", "format", "jpeg", "-s", "formatOptions", "88", ppm, "--out", destination],
      { stdio: "ignore" },
    );
  } finally {
    await fs.rm(ppm, { force: true });
  }
}

async function applyTheme(id) {
  execFileSync(
    "/bin/bash",
    [path.join(scriptsRoot, "manager-command-macos.sh"), "switch", "--id", id, "--apply-if-active"],
    { stdio: "inherit" },
  );
}

async function createSolid(options, libraryRoot) {
  const id = assertThemeID(options.id);
  if (!id.startsWith("custom-")) fail("新建主题 id 必须以 custom- 开头。");
  const name = options.name?.trim();
  if (!name || name.length > 80) fail("请提供 1–80 字符的 --name。");
  const primary = assertColor(options.primary, "主色");
  const secondary = assertColor(options.secondary ?? primary, "副色");
  const accent = assertColor(options.accent ?? secondary, "强调色");
  const output = path.resolve(options.output ?? path.join(os.tmpdir(), id));
  if (await isDirectory(output)) {
    if (!options.force) fail(`输出目录已存在：${output}。如需覆盖请添加 --force。`);
    await fs.rm(output, { recursive: true, force: true });
  }
  await fs.mkdir(output, { recursive: true, mode: 0o700 });
  await writeSolidArtwork(path.join(output, "background.jpg"), primary, secondary);
  const theme = {
    schemaVersion: 1,
    id,
    name,
    brandSubtitle: "CODEX DREAM SKIN",
    tagline: options.description ?? `${name} · 由 Codex Theme Studio Skill 生成`,
    statusText: "DREAM SKIN ONLINE",
    quote: "MAKE SOMETHING WONDERFUL",
    image: "background.jpg",
    catalog: {
      category: "solid",
      description: options.description ?? `${primary} → ${secondary}`,
      tags: ["纯色", primary, secondary],
      featured: false,
      source: "generated",
    },
    colors: {
      background: primary,
      panel: primary,
      panelAlt: secondary,
      accent,
      accentAlt: accent,
      secondary,
      highlight: accent,
      text: "#F6F7F9",
      muted: "#A8ADB7",
      line: `${accent}55`,
    },
  };
  await fs.writeFile(path.join(output, "theme.json"), `${JSON.stringify(theme, null, 2)}\n`, { mode: 0o600 });
  await validatePack(output);

  if (options.install) {
    const installed = await copyPackAtomically(output, libraryRoot, options.force);
    if (options.apply) await applyTheme(installed.id);
    return installed.directory;
  }
  return output;
}

async function main() {
  const { command, options } = parseArguments(process.argv.slice(2));
  const libraryRoot = path.resolve(options.library ?? defaultLibraryRoot);
  const installedIDs = new Set((await scanRoot(libraryRoot, "installed")).map((theme) => theme.id));

  if (command === "list" || command === "search") {
    const query = command === "search" ? (options.query ?? "").trim().toLocaleLowerCase("zh-Hans-CN") : "";
    const themes = (await catalog(libraryRoot))
      .filter((theme) => !query || searchableText(theme).includes(query))
      .map((theme) => publicTheme(theme, installedIDs));
    printThemes(themes, options.json);
    return;
  }

  if (command === "install") {
    const id = assertThemeID(options.id);
    const source = path.join(bundledRoot, id);
    if (!(await isDirectory(source))) fail(`内置目录中没有主题：${id}`);
    const installed = await copyPackAtomically(source, libraryRoot, options.force);
    if (options.apply) await applyTheme(installed.id);
    process.stdout.write(`${installed.directory}\n`);
    return;
  }

  if (command === "import") {
    if (!options.source) fail("import 需要 --source <主题目录>。");
    const installed = await copyPackAtomically(path.resolve(options.source), libraryRoot, options.force);
    if (options.apply) await applyTheme(installed.id);
    process.stdout.write(`${installed.directory}\n`);
    return;
  }

  if (command === "create-solid") {
    process.stdout.write(`${await createSolid(options, libraryRoot)}\n`);
    return;
  }

  fail("用法：theme-catalog.mjs <list|search|install|import|create-solid> [参数]");
}

main().catch((error) => {
  process.stderr.write(`Codex Theme Studio 主题目录：${error.message}\n`);
  process.exit(1);
});
