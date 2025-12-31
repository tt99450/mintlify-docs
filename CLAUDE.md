# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Mintlify documentation site for BigBlueButton. It includes:
- Getting started guides and essentials
- Help center documentation (user guide, moderator guide, admin, FAQ, troubleshooting)
- LMS integration guides (Canvas, Moodle, Sakai)
- API reference documentation

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

- **docs.json**: Central configuration file containing navigation structure (tabs, groups, pages), theming (colors, logos), and global settings
- **MDX files**: Documentation pages using MDX (Markdown + JSX components) with YAML frontmatter for `title` and `description`
- **snippets/**: Reusable content imported via `import MySnippet from '/snippets/my-snippet.mdx'` - these are NOT rendered as standalone pages
- **api-reference/**: API documentation with OpenAPI spec (`openapi.json`)
- **help/**: BigBlueButton help center organized by topic (user-guide, moderator-guide, admin, faq, troubleshooting, releases)
- **integrations/**: LMS integration guides (canvas, moodle, sakai)

## Navigation Structure

Navigation is defined in `docs.json` under `navigation.tabs`. Each tab contains groups, and each group contains page references (file paths without `.mdx` extension). The current tabs are:
- Guides (getting started, customization, writing content, AI tools)
- API reference
- Help Center
- Integrations

## Key Conventions

- Built-in Mintlify components are available in all MDX files: `<Card>`, `<Columns>`, `<Accordion>`, `<Steps>`, `<Note>`, `<Tip>`, `<Warning>`, `<Frame>`
- Images are stored in `/images/` and `/logo/` directories
- Page paths in `docs.json` use the file path without the `.mdx` extension (e.g., `"essentials/settings"` refers to `essentials/settings.mdx`)
- Snippets support props for dynamic content: `<MySnippet word="value" />`
