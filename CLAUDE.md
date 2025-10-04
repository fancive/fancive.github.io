# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Hugo static site blog publishing to GitHub Pages at https://fancive.github.io/. The site uses the [hugo-theme-dream](https://github.com/g1eny0ung/hugo-theme-dream) theme and publishes Chinese content focused on software architecture, Go programming, and AIOps topics.

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
# Build site (outputs to docs/ directory as configured in config.toml)
hugo

# Build including draft content
hugo -D

# Build and publish using automated script
./build.sh
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
- **Output directory**: `docs/` (configured via `publishDir` in config.toml)
- **Deployment**: GitHub Pages serves from the `docs/` folder on the main branch
- **Base URL**: https://fancive.github.io/

### Theme Management
- The site uses git submodules for theme management (see `.gitmodules`)
- Active theme: `dream` (located in `themes/dream/`)
- Other available themes in `themes/`: `ananke`
- To update theme submodules: `git submodule update --remote`

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
- Language: Chinese (zh-cn) with English support
- Comment system: Giscus (configured in `[params.giscus]`)
- Analytics: Google Analytics enabled (G-7N49ZFJ61J)

### Front Matter Structure
Posts should include (archetype template provides this structure):
```yaml
---
title: Post Title
date: 2025-01-30T14:07:06+08:00
lastmod: 2025-01-30T14:07:06+08:00
author: fancivez
cover: /images/covers/post-name.jpg
description: "Brief description for SEO"
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
Automated build and publishing workflow:
- Builds the Hugo site
- Detects changes in `docs/` directory
- Prompts for commit and push
- Includes deployment URL reminder

Usage: `./build.sh`

## Important Notes

- Content language is primarily Chinese (`languageCode = "zh-cn"`)
- The site includes both Chinese and English language support
- Disqus shortname configured but Giscus is the active comment system
- SEO features enabled: robots.txt, sitemap.xml, Google Analytics
- All categories and most tags should be in Chinese for consistency
- Use `<!--more-->` to mark excerpt break in posts
