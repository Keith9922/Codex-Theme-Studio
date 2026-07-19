# Codex Theme Studio Landing Page

产品落地页，只保留两条主要入口：

- 根据访问设备提示，直接下载 macOS Universal 2 App
- 复制 `create-codex-theme` 仓库链接，交给编程 AI 安装并制作主题

页面同时保留必要的兼容性、非官方、签名、本机调试接口、AI 服务隐私与素材权利说明。

## 本地运行

```bash
npm install
npm run dev
```

## 校验

```bash
npm test
```

页面使用 vinext 构建，并通过仓库内的 `.openai/hosting.json` 发布。
