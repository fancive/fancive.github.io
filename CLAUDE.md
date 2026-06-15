# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Hugo static site blog publishing to GitHub Pages at https://fancive.github.io/. The site uses the [PaperMod](https://github.com/adityatelange/hugo-PaperMod) theme and publishes Chinese content focused on three lines: Go backend engineering, AIOps/observability, and AI Agent engineering.

**Deployment**: GitHub Actions builds and deploys on every push to `main` (`.github/workflows/hugo.yml`). The build output (`public/`, and the legacy `docs/`) is git-ignored and NOT committed — never hand-edit or commit build artifacts.

## Build and Development Commands

### Local Development
```bash
# Start development server with drafts enabled
hugo server -D

# Start development server (published content only)
hugo server

# Auto-navigate to changed content
hugo server --navigateToChanged

# Full rebuild on changes (for debugging)
hugo server --disableFastRender
```

### Building and Publishing
```bash
# Local production build check (outputs to public/, git-ignored)
hugo --gc --minify

# Build including draft content
hugo -D

# Local preview (drafts on) — wraps `hugo server -D`
./build.sh serve

# Publishing is automatic: push to main → GitHub Actions builds & deploys.
# Do NOT commit build output.
```

### Content Management
```bash
# Create new post (uses archetype template with predefined fields)
hugo new posts/your-post-name.md

# Create new content in other sections
hugo new about.md
hugo new contact.md
```

## Architecture and Structure

### Publishing Configuration
- **Output directory**: `public/` (Hugo default; git-ignored)
- **Deployment**: GitHub Actions (`.github/workflows/hugo.yml`) builds with `hugo --gc --minify` and deploys via `actions/deploy-pages` on push to `main`. GitHub Pages source must be set to "GitHub Actions" (Settings → Pages).
- **Base URL**: https://fancive.github.io/

### Theme Management
- The site uses a single git submodule for the theme (see `.gitmodules`)
- Active theme: `PaperMod` (located in `themes/PaperMod/`)
- To update the theme: `git submodule update --remote themes/PaperMod`
- Custom CSS overrides live in `assets/css/extended/*.css` (auto-bundled by PaperMod)

### Content Organization
- Blog posts: `content/posts/*.md`
- Static pages: `content/about.md`, `content/contact.md`
- All content uses Hugo front matter with YAML format
- Draft posts should include `draft: true` in front matter

**Content Categories** (统一使用中文):
- `Go语言` - Go language articles and source code analysis
- `软件架构` - Software architecture and system design
- `AIOps` - AIOps research and paper reading
- `个人思考` - Personal reflections and annual reviews

### Site Configuration
- Main config: `config.toml` (Hugo TOML format)
- Language: Chinese only (`defaultContentLanguage = "zh-cn"`)
- Comment system: none currently. PaperMod supports giscus — to enable, override `layouts/partials/comments.html` and set `comments = true` in `[params]`.
- Analytics: Google Analytics enabled (G-7N49ZFJ61J)

### Front Matter Structure
Posts should include (archetype template provides this structure). Note `cover` is a **nested map** (PaperMod format), not a flat string. `author` is set site-wide in config.toml — don't repeat it per post:
```yaml
---
title: Post Title
date: 2025-01-30T14:07:06+08:00
lastmod: 2025-01-30T14:07:06+08:00
description: "Brief description for SEO"
cover:
  image: "/images/covers/post-name.jpg"
  alt: "..."
  caption: "..."
  # SVG covers must add: responsiveImages: false  (Hugo can't resize SVG)
categories:
  - Category Name
tags:
  - Tag1
  - Tag2
draft: true
---

<!--more-->
```

### Static Assets and Image Management
Image directory structure (see `static/images/README.md` for details):
```
static/images/
├── covers/          # Article cover images
├── posts/           # Article content images (organized by post name)
├── site/            # Site resources (logo, favicon, etc.)
└── illustrations/   # General illustrations
```

**Image Guidelines**:
- Cover images: `1200x630px`, stored in `/images/covers/`
- Article images: max width `1000px`, stored in `/images/posts/post-name/`
- Formats: JPEG for photos, PNG/SVG for icons/diagrams
- Always compress images before committing

### Custom Layouts
- Custom layout overrides can be placed in `layouts/_default/`
- Currently minimal custom layouts (theme provides defaults)

## Workflow Tools

### Build Script (`build.sh`)
Local-only helper (deployment is handled by GitHub Actions, not this script):
- `./build.sh serve` — local preview with drafts (`hugo server -D`)
- `./build.sh build` — production build check to `public/`

## Important Notes

- Content language is Chinese only (`defaultContentLanguage = "zh-cn"`); this also fixes JSON-LD `inLanguage` / `hreflang` which otherwise default to `en`.
- No comment system is wired up (PaperMod supports giscus if wanted).
- SEO features enabled: robots.txt, sitemap.xml, RSS/JSON output, Google Analytics, per-post `cover` as og:image (+ `params.images` fallback for the homepage).
- Categories should be a small stable set of Chinese topic domains (e.g. Go语言 / 软件架构 / AIOps / 方法论 / 个人思考). Don't put genre labels like 翻译/paper reading as categories. Tags: technical names in lowercase-hyphen English, topic words in Chinese.
- Use `<!--more-->` to mark excerpt break in posts.
- **Writing source**: long-form posts are drafted in the Obsidian vault `Writing/` (plain markdown, `>` blockquote lede, no frontmatter), then copied into `content/posts/` with Hugo frontmatter added. This copy is currently manual — keep the two in sync, or treat `content/posts/` as the published source of truth.
