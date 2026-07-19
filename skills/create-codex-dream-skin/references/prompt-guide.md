# Dream Skin 生图提示词

## 构图目标

- 横向 `2560×1440`，16:9
- 纯背景画面，不含任何软件界面
- 主体放在画面右侧约 58%–88%
- 左侧 50%–58% 保持低信息、低对比，供 Codex 标题和项目控件使用
- 主体与右边缘留出呼吸空间
- 光影和色彩从左向右自然过渡

## 提示词模板

```text
[主题与场景]，[材质/时代/视觉风格]，[主色与强调色]。
横向 16:9 环境背景，主体位于画面右侧 58%–88%，左侧大面积安静低对比留白，
适合作为深色/浅色桌面工作台背景，层次清楚但不干扰前景文字，
无界面、无窗口、无侧栏、无输入框、无卡片、无可读文字、无 Logo、无水印，
2560×1440。
```

## 负面词

```text
software UI, app window, dashboard, sidebar, text field, buttons, cards,
code editor screenshot, mockup, readable text, typography, logo, watermark,
frame, border, split screen, subject cropped by edge, busy left side
```

## 适配建议

- 深色主题：`appearance dark`，左侧压低亮度，强调色不超过画面 15%。
- 浅色主题：`appearance light`，避免纯白大面积过曝，保留灰阶层次。
- 标准人物/场景：`safe-area left` + `task-mode ambient`。
- 超宽城市或风景：可用 `task-mode banner`。
- 全幅纹理或纯色：`safe-area none`。

生成后先检查图片本身，不要把包含 Codex UI 的效果图作为背景导入。
