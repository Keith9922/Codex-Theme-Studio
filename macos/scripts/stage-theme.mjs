import fs from "node:fs/promises";
import { constants as fsConstants } from "node:fs";
import path from "node:path";

const [sourceDirArg, stageDirArg] = process.argv.slice(2);
if (!sourceDirArg || !stageDirArg) {
  throw new Error("Usage: stage-theme.mjs <source-theme-dir> <stage-dir>");
}

const MAX_CONFIG_BYTES = 1024 * 1024;
const MAX_IMAGE_BYTES = 16 * 1024 * 1024;
const MAX_DECORATIONS = 3;
const OPEN_FLAGS = fsConstants.O_RDONLY | (fsConstants.O_NOFOLLOW ?? 0);

function assertContained(rootPath, candidatePath, label) {
  const relative = path.relative(rootPath, candidatePath);
  if (
    relative === ""
    || (!path.isAbsolute(relative) && relative !== ".." && !relative.startsWith(`..${path.sep}`))
  ) return;
  throw new Error(`${label} must stay inside its theme directory`);
}

function sameStat(left, right) {
  return left.isFile() && right.isFile()
    && left.dev === right.dev
    && left.ino === right.ino
    && left.size === right.size
    && left.mtimeMs === right.mtimeMs
    && left.ctimeMs === right.ctimeMs;
}

async function readStableFile(filePath, label, maxBytes) {
  let handle;
  try {
    handle = await fs.open(filePath, OPEN_FLAGS);
  } catch (error) {
    if (error.code === "ELOOP") throw new Error(`${label} must not be a symbolic link`);
    throw error;
  }
  try {
    const before = await handle.stat();
    if (!before.isFile()) throw new Error(`${label} must be a regular file`);
    if (before.size > maxBytes) throw new Error(`${label} is larger than ${maxBytes} bytes`);
    const bytes = await handle.readFile();
    const after = await handle.stat();
    if (!sameStat(before, after)) {
      throw new Error(`${label} changed while it was being staged`);
    }
    if (bytes.length > maxBytes) throw new Error(`${label} is larger than ${maxBytes} bytes`);
    return { bytes, stat: after };
  } finally {
    await handle.close();
  }
}

function decodeJson(bytes, label) {
  const text = new TextDecoder("utf-8", { fatal: true }).decode(bytes);
  if (text.includes("\0")) throw new Error(`${label} contains NUL characters`);
  try {
    return JSON.parse(text);
  } catch {
    throw new Error(`${label} is not valid JSON`);
  }
}

function validateAssetName(value, label) {
  if (typeof value !== "string" || !value) {
    throw new Error(`${label} must be a non-empty filename`);
  }
  if (path.basename(value) !== value || value === "theme.json") {
    throw new Error(`${label} must stay inside its theme directory`);
  }
  if (/[\u0000-\u001f\u007f-\u009f\u2028\u2029]/u.test(value)) {
    throw new Error(`${label} contains control characters`);
  }
  if (!/\.(?:png|jpe?g|webp)$/i.test(value)) {
    throw new Error(`${label} has an unsupported image format`);
  }
  return value;
}

async function writeExclusive(filePath, bytes) {
  const temporary = `${filePath}.${process.pid}.tmp`;
  try {
    await fs.writeFile(temporary, bytes, { flag: "wx", mode: 0o600 });
    await fs.rename(temporary, filePath);
  } finally {
    await fs.rm(temporary, { force: true }).catch(() => {});
  }
}

async function main() {
  const sourceRoot = await fs.realpath(sourceDirArg);
  const sourceStat = await fs.stat(sourceRoot);
  if (!sourceStat.isDirectory()) throw new Error("Theme source must be a directory");

  const configPath = path.join(sourceRoot, "theme.json");
  const config = await readStableFile(configPath, "Theme config", MAX_CONFIG_BYTES);
  const theme = decodeJson(config.bytes, "Theme config");
  if (theme?.schemaVersion !== 1 || typeof theme.image !== "string" || !theme.image) {
    throw new Error("Theme config has an unsupported schema or image field");
  }
  validateAssetName(theme.image, "Theme image");
  if (theme.decorations !== undefined && !Array.isArray(theme.decorations)) {
    throw new Error("Theme decorations must be an array");
  }
  if ((theme.decorations?.length ?? 0) > MAX_DECORATIONS) {
    throw new Error(`Theme decorations must contain at most ${MAX_DECORATIONS} items`);
  }

  const assetNames = [theme.image];
  for (const [index, decoration] of (theme.decorations ?? []).entries()) {
    if (!decoration || typeof decoration !== "object" || Array.isArray(decoration)) {
      throw new Error(`Theme decoration ${index + 1} must be an object`);
    }
    assetNames.push(validateAssetName(decoration.image, `Theme decoration ${index + 1}`));
  }
  if (new Set(assetNames).size !== assetNames.length) {
    throw new Error("Theme asset filenames must be unique");
  }

  const assets = [];
  for (const [index, assetName] of assetNames.entries()) {
    const label = index === 0 ? "Theme image" : `Theme decoration ${index}`;
    const assetPath = path.resolve(sourceRoot, assetName);
    assertContained(sourceRoot, assetPath, label);
    const asset = await readStableFile(assetPath, label, MAX_IMAGE_BYTES);
    if (asset.bytes.length < 1) throw new Error(`${label} is empty`);
    assets.push({ name: assetName, bytes: asset.bytes });
  }

  const stageRoot = await fs.realpath(stageDirArg);
  const stageStat = await fs.stat(stageRoot);
  if (!stageStat.isDirectory()) throw new Error("Theme stage must be a directory");
  assertContained(stageRoot, path.join(stageRoot, "theme.json"), "Staged theme config");

  // Write every referenced asset from already-open, stable descriptors. The
  // caller publishes assets first and theme.json last, so the watcher only
  // observes a complete pack; subsequent source edits cannot race the copy.
  for (const asset of assets) {
    assertContained(stageRoot, path.join(stageRoot, asset.name), "Staged theme asset");
    await writeExclusive(path.join(stageRoot, asset.name), asset.bytes);
  }
  await writeExclusive(path.join(stageRoot, "theme.json"), config.bytes);
  process.stdout.write(theme.image);
}

await main();
