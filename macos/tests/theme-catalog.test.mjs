import assert from "node:assert/strict";
import fs from "node:fs/promises";
import path from "node:path";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const macosRoot = path.resolve(here, "..");
const catalogScript = path.join(macosRoot, "scripts", "theme-catalog.mjs");
const temporary = await fs.mkdtemp(path.join("/tmp", "dream-skin-catalog-"));
const library = path.join(temporary, "library");

function run(arguments_) {
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, [catalogScript, ...arguments_], {
      stdio: ["ignore", "pipe", "pipe"],
    });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => { stdout += chunk; });
    child.stderr.on("data", (chunk) => { stderr += chunk; });
    child.once("error", reject);
    child.once("close", (code) => {
      if (code === 0) resolve(stdout.trim());
      else reject(new Error(stderr || `theme-catalog exited with ${code}`));
    });
  });
}

try {
  const bundled = JSON.parse(await run(["search", "--query", "野生", "--library", library, "--json"]));
  assert.equal(bundled.length, 1);
  assert.equal(bundled[0].id, "preset-wild-museum");
  assert.equal(bundled[0].installed, false);

  await run(["install", "--id", "preset-wild-museum", "--library", library]);
  const installed = JSON.parse(await run(["search", "--query", "博物馆", "--library", library, "--json"]));
  assert.equal(installed[0].id, "preset-wild-museum");
  assert.equal(installed[0].installed, true);

  const customOutput = path.join(temporary, "custom-ocean-test");
  await run([
    "create-solid",
    "--id", "custom-ocean-test",
    "--name", "深海测试",
    "--primary", "#071521",
    "--secondary", "#123B52",
    "--accent", "#4DE2C5",
    "--output", customOutput,
    "--library", library,
    "--install",
  ]);
  const custom = JSON.parse(await run(["search", "--query", "深海", "--library", library, "--json"]));
  assert.equal(custom.length, 1);
  assert.equal(custom[0].category, "solid");
  assert.equal(custom[0].installed, true);
  assert.ok((await fs.stat(path.join(library, "custom-ocean-test", "background.jpg"))).size > 0);

  console.log("PASS: theme catalog searches, installs, and generates validated solid themes.");
} finally {
  await fs.rm(temporary, { recursive: true, force: true });
}
