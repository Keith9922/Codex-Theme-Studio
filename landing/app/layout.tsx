import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { headers } from "next/headers";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export async function generateMetadata(): Promise<Metadata> {
  const requestHeaders = await headers();
  const host =
    requestHeaders.get("x-forwarded-host") ??
    requestHeaders.get("host") ??
    "localhost:3000";
  const protocol =
    requestHeaders.get("x-forwarded-proto") ??
    (host.startsWith("localhost") ? "http" : "https");
  const metadataBase = new URL(`${protocol}://${host}`);
  const description =
    "下载 macOS App，复制 Theme Skill 链接给 AI，制作、导入并切换 Codex Desktop 主题。";

  return {
    metadataBase,
    title: "Codex Theme Studio — Codex 桌面主题管理器",
    description,
    keywords: [
      "Codex",
      "Codex Desktop",
      "macOS",
      "主题",
      "换肤",
      "Skill",
      "SwiftUI",
    ],
    icons: {
      icon: "/icon.png",
      shortcut: "/icon.png",
    },
    openGraph: {
      type: "website",
      title: "Codex Theme Studio",
      description: "Codex Desktop 主题管理器。下载 App，复制 Skill 链接给 AI。",
      images: [
        {
          url: "/og.png",
          width: 1731,
          height: 908,
          alt: "Codex Theme Studio — Theme manager for Codex Desktop.",
        },
      ],
    },
    twitter: {
      card: "summary_large_image",
      title: "Codex Theme Studio",
      description: "Codex Desktop 主题管理器。下载 App，复制 Skill 链接给 AI。",
      images: ["/og.png"],
    },
  };
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="zh-CN">
      <body className={`${geistSans.variable} ${geistMono.variable}`}>
        {children}
      </body>
    </html>
  );
}
