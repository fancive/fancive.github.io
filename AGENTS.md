# Repository Guidelines

## Project Structure & Module Organization
- `content/` holds source markdown; new posts belong in `content/posts/` and pages under `content/{about,contact}/`.
- `static/` exposes assets verbatim at publish time (images, downloads); reference them with absolute paths like `/images/...`.
- `layouts/` contains any theme overrides and shortcodes; keep custom HTML here instead of editing theme files directly.
- `docs/` is the generated site served by GitHub Pages—never edit it manually; run Hugo to refresh it before publishing.
- `themes/` tracks upstream themes (`dream` in use, `ananke` kept for reference); pull upstream updates via git submodule when needed.

## Build, Test, and Development Commands
- `hugo server -D` launches the live preview with drafts included at http://localhost:1313; reloads on file changes.
- `hugo --gc --minify -d docs` builds the production bundle, runs garbage collection on unused resources, and writes into `docs/`.
- `hugo new posts/<slug>.md` scaffolds a post using `archetypes/default.md`; edit front matter immediately after generation.

## Coding Style & Naming Conventions
- Author content in Markdown with UTF-8 encoding; keep front matter in YAML with `title`, `date`, `categories`, `tags`, and `featured_image` set.
- Use kebab-case filenames (e.g., `aiops-log-research.md`) and match the `slug` to the filename unless localization requires otherwise.
- Favor short paragraphs and insert `<!--more-->` where you want list previews to truncate.
- Keep TOML config changes tidy with two-space indentation and group related settings in `config.toml` blocks.

## Testing Guidelines
- After content or layout changes, run `hugo --gc --minify` and review the output for warnings about broken links or missing assets.
- Spot-check pages in the local preview on desktop and mobile breakpoints; verify localized menu items render as expected.
- If you touch JavaScript or CSS under `static/` or theme assets, clear the Hugo cache (`rm -rf resources/_gen`) to ensure fresh rebuilds.

## Commit & Pull Request Guidelines
- Follow the existing history: short, descriptive commit subjects (`change abstract`, `wheel of life 2024`) in the imperative mood work well.
- Include the regenerated `docs/` content in the same commit when publishing; omit it for draft-only work-in-progress branches.
- In pull requests, summarize the change scope, note any new content URLs, and attach screenshots for visual tweaks.
- Link issues or discussions when applicable and call out manual verification steps you performed (e.g., `hugo server -D`, mobile layout check).
