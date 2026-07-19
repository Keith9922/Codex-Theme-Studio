# create-codex-theme 使用指南

这个 Skill 与 **Codex Theme Studio** App 配套使用。安装完成后，你只需要输入一句自然语言，Skill 就会搜索或生成主题、执行安全校验并安装到本机主题库；App 随后可以识别并切换多套主题。

## 需要准备什么

- macOS 13 或更新版本
- 已安装并至少启动过一次官方 Codex Desktop
- 已安装 Codex Theme Studio App
- Codex 中可用的图像生成能力；纯色与渐变主题不需要图像生成

App 可从 [产品页](https://codex-theme-studio.zhangrg9922.chatgpt.site) 直接下载；Skill 推荐通过下面的仓库链接交给 AI 安装。

## 让 AI 帮你安装

复制下面这个链接：

```text
https://github.com/Keith9922/Codex-Theme-Studio/tree/main/skills/create-codex-theme
```

把链接和要求一起发给 Codex 或其他能访问 GitHub、本机文件和终端的编程 AI：

```text
请安装这个 Skill，然后帮我制作一套低饱和森林风格的 Codex 主题，生成后导入 Codex Theme Studio。
```

AI 应下载完整的 `create-codex-theme` 目录，将它安装到
`~/.codex/skills/create-codex-theme`，再按照 `SKILL.md` 制作和导入主题。

## 手动安装

如果当前 AI 无法访问 GitHub 或本机文件，也可以手动安装：

1. 下载 `create-codex-theme-skill-*.zip` 并解压。
2. 把整个 `create-codex-theme` 文件夹复制到：

   ```text
   ~/.codex/skills/create-codex-theme
   ```

3. 重新打开 Codex。
4. 在新任务中输入：

   ```text
   $create-codex-theme 帮我搜索一套墨绿色博物馆风格主题并安装。
   ```

如果 Codex 已经显示 `create-codex-theme` Skill，说明安装成功。

## 一句话生成主题

可以直接说明颜色、氛围、主体、构图、安全区和是否立即应用：

```text
$create-codex-theme 做一套黑紫青的赛博霓虹主题，主体靠右，左侧保持安静，生成后安装，暂时不要应用。
```

```text
$create-codex-theme 做一套浅色瓷白纸张主题，不要人物，不要文字，现在安装。
```

```text
$create-codex-theme 用我提供的猫咪照片做皮肤，主体不要被输入框挡住，安装后立即应用。
```

默认行为：

- 先搜索本机与内置主题
- 没有合适结果时才生成
- 生成后自动校验并安装
- 默认不立即应用
- 默认不启动或重启 Codex
- 不自动上传或公开发布私人主题

只有明确说“现在应用”时，Skill 才会执行主题切换；活动会话通常使用热切换。

## 在 App 中找到新主题

主题安装在：

```text
~/Library/Application Support/CodexDreamSkinStudio/themes
```

生成完成后：

1. 打开 `Codex Theme Studio.app`。
2. 工作台打开时会自动扫描主题库。
3. 如果 App 已经保持运行，点击主题库右侧的“刷新皮肤”。
4. 使用名称、颜色或风格搜索；也可以选择“纯色、氛围、人物、自定义”等分类。
5. 点击主题卡即可选择。皮肤已开启时会直接热切换。

每套主题使用独立目录，可以同时保留和切换多套主题。

## 产品配置

[`config/product.json`](./config/product.json) 定义 App 与 Skill 的共同约定，包括：

- App 最低版本
- Skill 安装目录
- 本机主题库位置
- 搜索、生成、安装、应用和重启的默认行为
- 主题包规范入口
- CDP、隐私和素材权利边界

查看配置：

```bash
scripts/codex-theme config
```

## 常见问题

### App 中看不到刚生成的主题

先点击“刷新皮肤”，并清除搜索词或切换到“全部”。如果仍然看不到，检查主题目录中是否同时包含 `theme.json` 与它引用的背景图。

### 生成后 Codex 为什么没有立即换肤

这是默认的安全行为。生成和安装不等于应用。请在 App 中选择主题，或明确要求 Skill“安装后立即应用”。

### 可以把角色或真人主题公开分享吗

只有在你拥有相应素材、肖像和再分发权利时才可以。个人使用不等于获得公开分发授权。

## 必要声明

- 本项目为非官方定制工具，与 OpenAI 无隶属、授权、赞助或背书关系。
- Codex 及相关商标归其权利人所有。
- 项目不修改官方 Codex App、`app.asar` 或代码签名。
- CDP 只监听 `127.0.0.1`，但调试端口本身具有较高权限；启用主题期间不要运行来源不明的本机程序。
- 公开 App 使用 ad-hoc 签名、尚未 Apple 公证；首次打开可能需要在 Finder 中右键选择“打开”。
- 主题图片与配置保存在本机，不会被项目主动上传。
- 使用受版权保护的角色、真人或第三方素材时，请自行确认生成、个人使用、商用和公开分发权利。
