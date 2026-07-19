"use client";

import { useEffect, useState } from "react";

const appDownloadUrl =
  "https://github.com/Keith9922/Codex-Theme-Studio/releases/download/v1.4.3/Codex-Theme-Studio-macOS-v1.4.3.zip";
const skillUrl =
  "https://github.com/Keith9922/Codex-Theme-Studio/tree/main/skills/create-codex-theme";

type NavigatorWithUAData = Navigator & {
  userAgentData?: {
    getHighEntropyValues(
      hints: string[],
    ): Promise<{ architecture?: string; bitness?: string }>;
  };
};

function detectSystem(userAgent: string) {
  if (/Macintosh|Mac OS X/i.test(userAgent)) return "macOS";
  if (/Windows/i.test(userAgent)) return "Windows";
  if (/Android/i.test(userAgent)) return "Android";
  if (/iPhone|iPad|iPod/i.test(userAgent)) return "iPhone / iPad";
  if (/Linux/i.test(userAgent)) return "Linux";
  return "当前设备";
}

export default function InstallActions() {
  const [device, setDevice] = useState("正在识别设备…");
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    let active = true;

    async function updateDevice() {
      const currentNavigator = navigator as NavigatorWithUAData;
      const system = detectSystem(currentNavigator.userAgent);

      if (system !== "macOS") {
        if (active) setDevice(`${system} · App 当前仅支持 macOS 13+`);
        return;
      }

      let label = "macOS · 通用版（Apple Silicon / Intel）";
      try {
        const values = await currentNavigator.userAgentData?.getHighEntropyValues([
          "architecture",
          "bitness",
        ]);
        const architecture = values?.architecture?.toLowerCase();
        if (architecture?.includes("arm")) {
          label = "macOS · Apple Silicon";
        } else if (architecture?.includes("x86")) {
          label = "macOS · Intel";
        }
      } catch {
        // Universal 2 remains the accurate fallback when architecture is hidden.
      }
      if (active) setDevice(label);
    }

    void updateDevice();

    return () => {
      active = false;
    };
  }, []);

  async function copySkillLink() {
    try {
      await navigator.clipboard.writeText(skillUrl);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1800);
    } catch {
      setCopied(false);
    }
  }

  return (
    <div className="install-grid">
      <article className="install-card download-card">
        <span className="card-label">APP</span>
        <h2>安装主题管理器</h2>
        <p className="device" aria-live="polite">{device}</p>
        <a className="download-button" href={appDownloadUrl}>
          下载 macOS App <span aria-hidden="true">↓</span>
        </a>
        <small>直接下载 v1.4.3 · Universal 2</small>
      </article>

      <article className="install-card skill-card">
        <span className="card-label">THEME SKILL</span>
        <h2>把链接交给 AI</h2>
        <div className="skill-link">
          <code>{skillUrl}</code>
          <button type="button" onClick={copySkillLink} aria-live="polite">
            {copied ? "已复制" : "复制链接"}
          </button>
        </div>
        <p>复制后告诉 AI：“安装这个 Skill，然后帮我制作一套喜欢的 Codex 主题。”</p>
      </article>
    </div>
  );
}
