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
    <div className="action-console">
      <div className="device-row">
        <span className="device-status"><i aria-hidden="true" />{device}</span>
        <span>v1.4.3 · Universal 2</span>
      </div>
      <div className="action-row">
        <a className="download-button" href={appDownloadUrl}>
          <span>下载 macOS App</span>
          <i aria-hidden="true">↓</i>
        </a>
        <button
          className={`copy-button${copied ? " is-copied" : ""}`}
          type="button"
          onClick={copySkillLink}
          aria-live="polite"
        >
          <span aria-hidden="true">{copied ? "✓" : "⌘"}</span>
          {copied ? "Skill 链接已复制" : "复制 Skill 链接"}
        </button>
      </div>
      <div className="skill-line">
        <span>SKILL</span>
        <code>{skillUrl}</code>
      </div>
      <p>复制后交给 AI：“安装这个 Skill，然后帮我制作一套喜欢的 Codex 主题。”</p>
    </div>
  );
}
