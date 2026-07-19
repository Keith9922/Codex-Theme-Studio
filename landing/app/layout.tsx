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
    "原生 macOS Codex 主题管理器与制皮 Skill。一句话生成、自动安装、App 直接识别并自由切换多套主题。";

  return {
    metadataBase,
    title: "Codex Theme Studio — 一句话生成并切换 Codex 主题",
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
      description: "一句话生成，自动安装，随意切换多个 Codex 主题。",
      images: [
        {
          url: "/og.png",
          width: 1730,
          height: 909,
          alt: "Codex Theme Studio — One sentence. Infinite themes.",
        },
      ],
    },
    twitter: {
      card: "summary_large_image",
      title: "Codex Theme Studio",
      description: "一句话生成，自动安装，随意切换多个 Codex 主题。",
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
