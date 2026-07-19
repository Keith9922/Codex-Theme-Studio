import assert from "node:assert/strict";
import fs from "node:fs/promises";
import test from "node:test";

async function render() {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request("https://codex-theme-studio.example/", {
      headers: {
        accept: "text/html",
        host: "codex-theme-studio.example",
        "x-forwarded-host": "codex-theme-studio.example",
        "x-forwarded-proto": "https",
      },
    }),
    {
      ASSETS: {
        fetch: async () => new Response("Not found", { status: 404 }),
      },
    },
    {
      waitUntil() {},
      passThroughOnException() {},
    },
  );
}

test("renders the product landing page and share metadata", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);

  const html = await response.text();
  assert.match(html, /Codex Theme Studio/);
  assert.match(html, /给 Codex 换个主题。/);
  assert.doesNotMatch(html, /给 Codex\s*<br/);
  assert.match(html, /复制 Skill 链接/);
  assert.match(html, /v1\.4\.3 · Universal 2/);
  assert.match(html, /releases\/download\/v1\.4\.3/);
  assert.match(html, /tree\/main\/skills\/create-codex-theme/);
  assert.match(html, /非官方项目/);
  assert.match(html, /og\.png/);
  assert.doesNotMatch(
    html,
    /完整世界|PRODUCT CAPABILITIES|ONE CONFIG|127\.0\.0\.1|获取制皮 Skill|下载 Skill|codex-preview|Your site is taking shape/,
  );
});

test("keeps the hero on one line and provides accessible motion fallbacks", async () => {
  const css = await fs.readFile(
    new URL("../app/globals.css", import.meta.url),
    "utf8",
  );
  assert.match(css, /\.hero h1\s*\{[\s\S]*?white-space:\s*nowrap/);
  assert.match(css, /@keyframes title-enter/);
  assert.match(css, /@keyframes preview-enter/);
  assert.match(css, /@media \(prefers-reduced-motion: reduce\)/);
});
