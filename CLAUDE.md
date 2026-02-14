# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Mintlify documentation site for BigBlueButton, an open-source virtual classroom platform. The docs are organized around a **Prepare → Educate → Reflect** teaching workflow, plus reference material, LMS integrations, and premium features.

## Development Commands

```bash
# Install CLI (requires Node.js 19+)
npm i -g mint

# Start local preview server (default http://localhost:3000, auto-increments if taken)
npx mint dev --port 3333

# Validate links in documentation
npx mint broken-links
```

## Architecture

- **docs.json**: Single source of truth for all site configuration — navigation tabs/groups/pages, theming, navbar, footer. Every page must be listed here to appear in navigation.
- **MDX files**: Documentation pages with YAML frontmatter (`title`, `description`, optional `icon`). Page paths in `docs.json` omit the `.mdx` extension.
- **snippets/**: Reusable content fragments imported via `import MySnippet from '/snippets/my-snippet.mdx'` — NOT rendered as standalone pages.
- **images/**: All documentation images; subdirectories mirror content structure.
- **index.mdx**: Homepage, auto-served at `/` — does not need a navigation entry.

## Navigation Structure

Navigation is defined in `docs.json` under `navigation.tabs`. Current tabs:

1. **Getting Started** — Welcome, before-you-teach checklist, accessibility, interface overview, quick reference
2. **1-Prepare** — Room setup, content creation (hub pages linking to detail pages in `help/`)
3. **2-Educate** — Manage class, build relationships, teach, active learning, assess & feedback
4. **3-Reflect** — Recordings, review your class
5. **Reference** — Practical tips, troubleshooting, keyboard shortcuts, FAQ, premium features, troubleshooting guides, release notes
6. **Integrations** — Canvas, Moodle, Sakai LMS guides (uses `menu` with sub-items)
7. **Premium** — Personal Rooms and Analytics (uses `menu` with sub-items)

### Content Architecture

- **Hub pages** (`getting-started/`, `prepare/`, `educate/`, `reflect/`, `reference/`): Consolidate and link to existing detail pages — no content duplication.
- **Detail pages** (`help/user-guide/`, `help/presenter-guide/`, `help/moderator-guide/`): Original granular content, accessible via links from hub pages but not listed directly in sidebar navigation.
- **Legacy content** (`help/faq/`, `help/premium/`, `help/troubleshooting/`, `help/releases/`): Listed directly in the Reference tab.
- **Integrations** and **Premium** tabs use the `menu` → `item` → `groups` pattern for sub-navigation.

## Key Conventions

- Available Mintlify components: `<Card>`, `<CardGroup>`, `<Columns>`, `<Tabs>`, `<Tab>`, `<Accordion>`, `<AccordionGroup>`, `<Steps>`, `<Note>`, `<Tip>`, `<Warning>`, `<Frame>`, `<Latex>`
- When adding a new page: create the `.mdx` file AND add its path to the appropriate group in `docs.json`
- Images go in `/images/` (mirroring content directory structure), logos in `/logo/`
- Hub pages use `<Card>` with `href` links to detail pages rather than duplicating content
- No package.json or build system — Mintlify CLI handles everything
- Deployments happen automatically when pushing to the default branch (via Mintlify GitHub app)
