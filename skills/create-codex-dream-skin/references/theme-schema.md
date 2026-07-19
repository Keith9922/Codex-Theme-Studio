# Dream Skin 主题包规范

主题包是一个独立文件夹，目录名必须与 `theme.json.id` 完全一致。

```text
custom-rain-radio/
├── theme.json
└── background.jpg
```

最小配置：

```json
{
  "schemaVersion": 1,
  "id": "custom-rain-radio",
  "name": "雨夜电台",
  "image": "background.jpg"
}
```

推荐目录元数据：

```json
{
  "catalog": {
    "category": "solid",
    "description": "近黑蓝与低饱和电光青",
    "tags": ["纯色", "深色", "雨夜", "青色"],
    "featured": false,
    "source": "generated"
  }
}
```

分类值：

- `solid`：程序化纯色或克制渐变
- `abstract`：抽象氛围背景
- `character`：人物/角色背景
- `custom`：用户导入
- `other`：其他

可选自适应字段：

```json
{
  "appearance": "auto",
  "art": {
    "focusX": 0.72,
    "focusY": 0.45,
    "safeArea": "left",
    "taskMode": "ambient"
  }
}
```

约束：

- id：1–80 字符，仅限字母、数字、`-`、`_`
- 图片名：只能是同目录单个文件名，不能含路径
- 格式：PNG、JPEG 或 WebP
- 准备后的图片不超过 16 MB、单边不超过 16384px、总像素不超过 50MP
- 主题包不允许符号链接或目录穿越
- `appearance`：`auto` / `light` / `dark`
- `safeArea`：`auto` / `left` / `right` / `center` / `none`
- `taskMode`：`auto` / `ambient` / `banner` / `off`
