# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Mintlify documentation site for BigBlueButton, a video conferencing platform. The site covers getting started guides, a help center (user/presenter/moderator guides, FAQ, troubleshooting), LMS integration guides (Canvas, Moodle, Sakai), personal rooms documentation, LMS analytics, and an API reference.

## Development Commands

```bash
# Install CLI (requires Node.js 19+)
npm i -g mint

# Start local preview server (runs at http://localhost:3000)
mint dev

# Run on custom port
mint dev --port 3333

# Update CLI to latest version
mint update

# Validate links in documentation
mint broken-links
```

## Architecture

- **docs.json**: Central configuration file — contains all navigation (tabs, groups, pages), theming (colors, logos), navbar, footer, and global settings. This is the single source of truth for site structure.
- **MDX files**: Documentation pages using MDX (Markdown + JSX components) with YAML frontmatter (`title`, `description`, optional `icon`)
- **snippets/**: Reusable content imported via `import MySnippet from '/snippets/my-snippet.mdx'` — these are NOT rendered as standalone pages and support props
- **api-reference/**: API documentation with OpenAPI 3.1.0 spec (`openapi.json`)
- **help/**: BigBlueButton help center organized into subdirectories: `user-guide/`, `presenter-guide/`, `moderator-guide/`, `premium/`, `personal-rooms/`, `getting-started/`, `faq/`, `troubleshooting/`, `releases/`
- **integrations/**: LMS integration guides in subdirectories: `canvas/`, `moodle/`, `sakai/`
- **analytics/**: LMS analytics documentation (overview, configuration, per-LMS guides, data formats)
- **images/**: All documentation images (~163 MB); subdirectories mirror content structure

## Navigation Structure

Navigation is defined in `docs.json` under `navigation.tabs`. Each tab contains groups, and each group contains page references (file paths without `.mdx` extension). Current tabs:

1. **Guides** — Getting started, customization, writing content, AI tools
2. **API reference** — API documentation and endpoint examples
3. **Help Center** — User guide, presenter guide, moderator guide, premium features, FAQ, troubleshooting, release notes
4. **Integrations** — Canvas, Moodle, Sakai LMS guides
5. **Personal Rooms** — Personal rooms management, authentication (OAuth, SAML), admin panel
6. **Analytics** — LMS analytics configuration and data formats

## Key Conventions

- Built-in Mintlify components available in all MDX files: `<Card>`, `<CardGroup>`, `<Columns>`, `<Accordion>`, `<AccordionGroup>`, `<Steps>`, `<Note>`, `<Tip>`, `<Warning>`, `<Frame>`, `<Latex>`
- Page paths in `docs.json` use the file path without the `.mdx` extension (e.g., `"essentials/settings"` refers to `essentials/settings.mdx`)
- Images go in `/images/` (mirroring content directory structure) and logos in `/logo/`
- When adding a new page: create the `.mdx` file AND add its path to the appropriate group in `docs.json`
- No package.json or build config — Mintlify CLI is installed globally and handles all building/serving
