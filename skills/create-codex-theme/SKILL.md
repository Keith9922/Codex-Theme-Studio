---
name: create-codex-theme
description: 搜索、生成、导入、安装和切换 Codex Theme Studio 主题。适用于用户描述想要的 Codex 外观、颜色、人物或氛围，希望查找已有皮肤、安装内置皮肤、把本地图片制成皮肤，或生成一套新主题时。支持程序化纯色主题与图像主题，并在导入前执行主题包和图片安全校验。
---

# 制作 Codex Theme Studio 主题

把自然语言主题要求转换成可安装的 Codex Theme Studio 主题包。始终先搜索本机与内置目录；已有匹配项时优先复用，没有合适结果时再生成。

开始工作前读取 `config/product.json`。它定义 App 最低版本、主题库位置、默认安装行为和安全边界。除非用户明确覆盖，生成完成后应自动安装到主题库，但不立即应用、不重启 Codex。

面向普通用户时，推荐的完整使用方式只有三步：

1. 安装 Codex Theme Studio App。
2. 把本 Skill 文件夹放入 `~/.codex/skills/create-codex-theme`。
3. 输入一句话，例如：`$create-codex-theme 做一套低饱和森林主题，生成后安装，暂时不要应用。`

主题安装完成后，App 在打开工作台或点击“刷新皮肤”时会读取它。用户可以保留任意多套有效主题并随时切换。

## 工作流

### 1. 定位工具并搜索

所有确定性操作都通过本 Skill 的脚本执行：

```bash
scripts/codex-theme list
scripts/codex-theme search --query "赛博 霓虹"
scripts/codex-theme config
```

搜索结果包含主题 id、名称、分类、说明和安装状态。关键词可使用中文、英文、颜色、氛围或主题 id；本机已有的私人皮肤也会出现在结果中。

如果找到了匹配主题：

```bash
scripts/codex-theme install --id preset-cyber-neon
```

`install` 默认只安装/选择，不启动或重启 Codex。用户明确要求立即应用时，可添加 `--apply`；活动会话会热切换。

### 2. 选择生成方式

- 用户只要颜色、渐变、极简或无图案主题：生成程序化纯色主题。
- 用户提供了图片：直接导入图片主题。
- 用户描述了人物、场景、材质或叙事画面：先生成一张无 UI 背景，再导入。
- 用户要求受版权保护的角色、真人或第三方素材：提醒其确认个人使用与再分发权利；不要把此类素材加入公开内置目录。

生成前读取：

- 主题字段和目录约束：`references/theme-schema.md`
- 生图构图、提示词与负面词：`references/prompt-guide.md`

### 3A. 生成纯色主题

为 id 使用小写英文/数字/连字符，并以 `custom-` 开头。色值必须是 `#RRGGBB`：

```bash
scripts/codex-theme create-solid \
  --id custom-deep-ocean \
  --name "深海控制室" \
  --primary "#071521" \
  --secondary "#123B52" \
  --accent "#4DE2C5" \
  --description "低饱和深海蓝与一束薄荷绿" \
  --install
```

脚本会生成 `1920×1200` JPEG、写入元数据、校验主题包并原子安装。只有用户明确要求立即应用时才添加 `--apply`。

### 3B. 生成图像主题

使用可用的 `$imagegen` Skill 或图像生成工具，生成横向、无界面、无文字、无 Logo 的背景图。推荐 `2560×1440`，主体位于右侧 58%–88%，左侧保持低信息与低对比。不要生成 Codex 窗口、侧栏、输入框、卡片或效果截图。

生成文件后，先不重启地导入：

```bash
scripts/codex-theme image \
  --file "/absolute/path/background.png" \
  --name "雨夜电台" \
  --appearance dark \
  --safe-area left \
  --task-mode ambient
```

默认行为是生成、校验、保存到主题库，但不应用。用户已经明确授权启动/重启 Codex 时添加 `--apply`。

### 3C. 导入现有主题包

主题包必须是一个含 `theme.json` 与同目录背景图的文件夹：

```bash
scripts/codex-theme import \
  --source "/absolute/path/custom-theme-pack"
```

导入过程拒绝路径穿越、符号链接、超限图片和无效字段。覆盖同名自定义主题必须显式添加 `--force`。

### 4. 校验与交付

安装完成后再次搜索并核对：

```bash
scripts/codex-theme search --query "主题名称"
scripts/codex-theme status
```

向用户报告主题名称、id、安装位置、是否已应用，以及是否发生过 Codex 重启。不要声称未公证的 App 或第三方素材可以无条件公开分发。

## 常用请求示例

- “找一个墨绿色、像自然历史博物馆的主题并安装。”
- “生成一套黑紫青的赛博霓虹皮肤，现在就应用。”
- “用这张猫咪照片做皮肤，主体不要被输入框挡住。”
- “做一套浅色瓷白主题，只导入，暂时不要重启 Codex。”
- “搜索我以前装过的明日香主题并切换过去。”

## 安全与行为边界

- CDP 只允许绑定 `127.0.0.1`；不要扩大监听范围。
- 不修改 Codex 官方 `.app`、`app.asar` 或签名。
- 搜索、生成、校验和安装不需要重启；只有显式 `--apply` 或启用皮肤可能启动/重启 Codex。
- 公开主题只使用原创、已授权、CC0/公有领域或程序化素材。
- 保留用户现有主题，不删除无关的 `custom-*` / `img-*` 目录。
