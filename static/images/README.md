# 图片管理说明

本目录用于存放博客所需的各类图片资源。

## 目录结构

```
images/
├── covers/          # 文章封面图片
│   └── default.jpg  # 默认封面
├── posts/           # 文章内容图片（按文章名分文件夹）
│   ├── post-name-1/
│   └── post-name-2/
├── site/            # 站点资源图片
│   ├── profile.jpg  # 个人头像
│   ├── background.jpg
│   └── globe.svg
└── illustrations/   # 其他插图（已有）
```

## 命名规范

### 封面图片
- 存放路径: `covers/`
- 命名格式: `post-slug.jpg` 或 `post-slug.png`
- 在文章中引用: `/images/covers/post-slug.jpg`

### 文章内图片
- 存放路径: `posts/post-name/`
- 命名格式: 描述性名称，如 `architecture-diagram.png`
- 在文章中引用: `/images/posts/post-name/architecture-diagram.png`

### 站点资源
- 存放路径: `site/`
- 命名格式: 功能性名称，如 `logo.png`, `favicon.ico`

## 图片优化建议

1. **格式选择**
   - 照片类: 使用 JPEG
   - 图标/插图: 使用 PNG 或 SVG
   - 动图: 使用 GIF 或 WebP

2. **尺寸要求**
   - 封面图: 建议 1200x630px (社交媒体分享尺寸)
   - 文章内图: 建议宽度不超过 1000px
   - 头像: 建议 400x400px

3. **压缩优化**
   - 使用工具压缩图片以提升加载速度
   - 推荐工具: TinyPNG, ImageOptim
