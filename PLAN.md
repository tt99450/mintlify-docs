# Plan: Analyze BigBlueButton Docs for Quality, Readability, Accuracy

## Context

The repo contains 191 `.mdx` files documenting BigBlueButton. Style and structure have drifted across contributors and eras: hub pages (`getting-started/`, `prepare/`, `educate/`, `reflect/`) follow a modern Card-based pattern, while legacy `help/faq/`, `help/troubleshooting/`, and `help/*-guide/` pages vary in tone, completeness, and UI accuracy. The `improve-kb-article` skill (`~/.claude/skills/improve-kb-article/SKILL.md`) defines a gold-standard style, but it has only been applied to some pages. The user wants a systematic way to find and rank which files most need attention across three dimensions: quality (style/structure), readability (prose clarity), and accuracy (UI/feature correctness).

The goal of this plan is to produce a triaged audit report — not to rewrite pages. Rewriting is a follow-up step, page by page, using the existing `improve-kb-article` and `update-screenshots` skills.

## Current baseline (as of 2026-04-25)

- `npx mint broken-links`: **0 broken links**. The previously-cited "33 known-broken" baseline was cleared in the recent broken-link fix pass (29 links across 13 files repointed at correct legacy targets).
- `npx mint a11y` (image/video alt text): **0 issues**. 47 missing alt attributes across 19 files were filled in the recent a11y pass.
- `npx mint a11y` (color contrast): **1 known failure** — primary color `#16A34A` vs. light background scores 3.30:1, fails WCAG AA (4.5:1). This is a `docs.json` theme issue, not a per-page issue, and will recur in every Layer 1 run until the theme color is updated.
- One missing image asset (`/images/analytics/Screenshot2026-03-16at6.52.27PM.png`) was removed from `help/presenter-guide/shared-notes-presenter.mdx` rather than re-captured — flag for future screenshot refresh if that visual is wanted back.

## Scope math

- Total `.mdx`: 191 (per `mint a11y` count) — exact split between snippets/homepage/content pages to be confirmed by Layer 1's `find` pass and recorded in `audit/00-scope.md`.
- Tier A (full Layer-2 pass): `help/faq/`, `help/troubleshooting/`, `help/*-guide/` — exact count determined by `find` during Layer 1.
- Tier B (Layer-2 spot-check): 5 random pages per hub section (`getting-started/`, `prepare/`, `educate/`, `reflect/`, `reference/`), plus any hub page flagged by Layer 1.
- Tier C (skipped): `snippets/`, `index.mdx`.
- Final dashboard target: all content pages carry at least a Layer-1 signal; Tier A + B carry a Layer-2 score; Layer-3 covers the top 20 worst-scoring Tier-A pages.

## Approach: Three-Layer Audit

### Layer 1 — Automated checks (fast, deterministic)

Run existing Mintlify tooling and capture output:

```bash
npx mint validate       # schema / frontmatter / component errors (strict)
npx mint broken-links   # baseline: 0 (was 33; cleared in recent pass)
npx mint a11y           # alt text, heading order, color contrast
```

Filter `mint a11y` color-contrast output against an "accepted" list (currently the `#16A34A` primary-color failure) so per-page signal isn't drowned in recurring theme-level noise. Better: fix the theme color in `docs.json` and drop the filter.

Scripted checks over all `.mdx` files (only those *not* already covered by Mint tooling):
- **Frontmatter completeness**: missing `title` or `description`.
- **Orphan pages**: file exists on disk but not referenced in `docs.json`. The script must walk nested structures (`navigation.tabs[].groups[].pages[]`, and `tabs[].menu[].item[].groups[].pages[]` for Integrations and Premium) — a flat scan of `pages:` arrays will produce false positives.
- **Broken image paths**: `<Frame>` / `![]()` / `<img src=…>` pointing to non-existent files in `/images/`. (Alt-text presence is already covered by `mint a11y` — don't reimplement.)
- **Stub pages**: body under ~200 chars or TODO markers.
- **Duplicate titles** across the set.
- **Hub→detail link graph**: since `mint broken-links` already covers internal links, rely on it rather than reimplementing — but note in the report that hub→detail is the architecture's main load-bearing pattern, so broken links there rank higher in severity.

Output: `audit/01-automated.md` — table of files × issues, plus the exact Tier-A count for downstream sizing.

### Layer 2 — Style & readability audit (rubric-based)

Score each page against the `improve-kb-article` rubric. **Before writing the scoring prompt, read `~/.claude/skills/improve-kb-article/SKILL.md` and derive the criteria verbatim from that file.** The criteria listed below are a working hypothesis; if the skill disagrees, the skill wins — we don't want the rubric to drift from the canonical style guide.

Working-hypothesis criteria (to be reconciled with SKILL.md):
1. **Opening**: paragraph 1 states who + what enablement.
2. **Voice**: active, present tense; no "will be displayed", "it is important to note", "be sure to".
3. **UI callouts**: clickable labels bold; numbered callouts `[1]`, `[2]` match image reading order.
4. **Terminology**: "select" not "click"; lowercase roles. *(Verify whether SKILL.md prescribes "session" vs. "meeting" before including that axis — don't score on unsourced rules.)*
5. **Structure**: one idea per paragraph; appropriate use of `<Steps>`, `<Note>`, `<Warning>`, `<Tabs>`, `<Accordion>`.
6. **Result confirmation**: each action states the visible outcome.
7. **Length fit**: hub pages concise + Card-linked; how-to pages have numbered steps with screenshots.

**Implementation vehicle.** Default to dispatching one `Agent` per page (or per small batch) from a Claude Code session, with the rubric and `improve-kb-article` skill loaded as context. The recent broken-link and a11y passes confirmed that direct interactive work scales fine at this cardinality and avoids the friction of a separate SDK pipeline (env vars, API keys, batching code). Only fall back to a batched Anthropic SDK script if Tier A turns out larger than ~150 files and per-page interactive cost becomes painful.

**Cost/time budget.** Tier A is estimated at 80–120 files (to be confirmed by Layer 1). One agent per page, with prompt caching of the rubric, is the expected hot path; budget a few minutes per page for Layer-2 scoring.

Outputs: `audit/02-style.json` (raw) and `audit/02-style.md` (rendered, sorted worst-first). Only `top_3_issues` are surfaced per page — note that criteria 4–7 are therefore under-sampled in the rendered report; the raw JSON retains full scores for reproducibility.

### Layer 3 — Accuracy audit (manual / UI-assisted, sampled)

Accuracy can't be fully automated. Approach:

- **Screenshot staleness.** Flag pages whose `/images/` paths have a last-touch commit older than the most recent UI-bearing commit in the same feature area (e.g., a conferences page with screenshots from before `ba99340` / `5953216` — the recent conference-management refresh). The git-mtime heuristic is noisy: bulk reorganization commits can touch many images at once without a real UI change. Cross-check by also flagging pages whose *prose* references UI labels absent from current screenshots.
- **Dedupe against recent work.** Skip any page whose images were touched in the last 30 commits — those were just refreshed and shouldn't re-enter Layer 3.
- **Terminology drift.** Flag pages referencing labels that don't match current terminology (cross-check against `educate/` hub pages, the freshest source of truth).
- **Top-20 live verification.** For the top 20 worst-scoring Tier-A pages from Layer 2 (after dedupe), use `update-screenshots` + Playwright MCP against a live BBB session to verify each documented step still works.

Output: `audit/03-accuracy.md` — page × verified/stale/unknown, with notes.

## Final deliverable

`audit/README.md` — triage dashboard:

```
┌──────────┬──────┬─────────────┬─────────────┬──────────┬────────────────────┐
│ Priority │ Page │ Auto issues │ Style score │ Accuracy │ Recommended action │
├──────────┼──────┼─────────────┼─────────────┼──────────┼────────────────────┤
```

Sort by a **reproducible severity score**:

```
severity = (auto_issues_count * 2) + (5 - style_score) + accuracy_penalty
  where accuracy_penalty = 3 if stale, 1 if unknown, 0 if verified
```

Weights are a starting point — expect to retune after eyeballing the first sorted output (e.g., a single missing image currently equals two style-score points, which may over- or under-weight depending on what the early results show).

Rows link to per-layer reports.

## Open question: is the dashboard worth building?

The recent broken-link (29 fixes) and a11y (47 alt-text fixes across 19 files) passes were driven *directly* by `mint broken-links` and `mint a11y` output, with no dashboard in between. That suggests Layer 1 plus the existing `improve-kb-article` and `update-screenshots` skills may be enough to walk Tier A page-by-page without constructing an audit artifact at all. Before building Layer 2/3 infrastructure, decide:

- Will the dashboard actually be re-read (i.e., is triage value > construction cost)?
- Or is it cheaper to just iterate through Tier A interactively and let Layer 1 + the skills do the work?

If the answer is "iterate directly," skip Layers 2 and 3 and go straight to per-page work driven by `improve-kb-article`.

## Commit policy

`audit/` is **gitignored** by default. The dashboard churns on every rescore, and a repo with 187 files in a dashboard is better regenerated than reviewed in diffs. Promote individual findings to commits (as edits to the actual pages) rather than committing audit state. Add `audit/` to `.gitignore` as part of Layer 1 setup.

## Critical files

- `/home/ubuntu/dev/mintlify-docs/docs.json` — source of truth for navigation; used for orphan detection (nested walk required).
- `/home/ubuntu/dev/mintlify-docs/CLAUDE.md` — project conventions.
- `/home/ubuntu/.claude/skills/improve-kb-article/SKILL.md` — the style rubric; reuse verbatim, do not duplicate or paraphrase.
- `/home/ubuntu/.claude/skills/update-screenshots/` — reused in Layer 3.
- New files under `/home/ubuntu/dev/mintlify-docs/audit/` (gitignored).

## Reused vs. new

- **Reuse**: `mint validate`, `mint broken-links`, `mint a11y`, `improve-kb-article`, `update-screenshots`, Playwright MCP.
- **New**: small audit scripts (frontmatter check, orphan check with nested-nav walk, image existence check), the batched SDK-driven rubric pass, and the report files under `audit/`. No new lint dependencies, no `package.json`.

## Verification

1. `npx mint validate` exits clean or with a known, documented list of errors.
2. `npx mint broken-links` reports 0 (current baseline). `npx mint a11y` reports 0 image/video alt-text issues; the only remaining a11y warning is the known `#16A34A` color-contrast failure (or it's been fixed in `docs.json`).
3. `audit/README.md` exists and lists Tier A + B content pages with Layer-1 signal and (if Layer 2 was run) Layer-2 scores; Layer 3 covers the top 20.
4. Spot-check: pick 3 pages flagged "high priority" and manually confirm the issues are real.
5. Spot-check: pick 3 pages scored "clean" and confirm they read well — catches false negatives in the rubric pass.
6. Re-running Layer 1 after a page edit shows the Layer-1 issue resolved. (Layers 2 and 3 are regenerated on demand, not on every edit — cost lives there.)

## Out of scope

- Actually rewriting pages — follow-up work, one page at a time via the existing skills, driven by the dashboard.
- Capturing new screenshots broadly — only for the top-20 Layer-3 pages.
- Adding CI / GitHub Actions — not requested; Mintlify auto-deploys on push.
