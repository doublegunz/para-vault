# Repository Guidelines

## Project Structure & Module Organization

This repository is an Obsidian vault organized with the PARA method (Projects, Areas, Resources, Archives). It is a personal knowledge management system; content is Markdown-first and should remain easy to browse in Obsidian.

- `00-inbox/`: quick captures, drafts, and unprocessed notes.
- `01-projects/`: active work with goals, deadlines, or deliverables.
- `02-areas/`: ongoing responsibilities without a fixed end date.
- `03-resources/`: reference material, learning notes, and reusable documentation.
- `04-archives/`: completed, inactive, or superseded material.
- `sandbox/`: ignored local workspace for testing tutorial commands and sample projects. The folder is kept in Git with `.gitkeep`, but its contents are ignored.
- `.obsidian/`: local Obsidian configuration. `workspace.json` is ignored because it is device-specific.

Place new notes in the folder that matches their current status. Move notes as their status changes instead of duplicating them.

## Build, Test, and Development Commands

There is no application build pipeline or package manager in this vault. Useful local checks are:

- `find . -name '*.md' | sort`: list Markdown notes.
- `git status --short`: review changed files before committing.
- `git diff -- README.md 03-resources/example.md`: inspect note edits.

Open the repository as an Obsidian vault to preview wikilinks, backlinks, tags, and rendered Markdown.

Use `sandbox/` for hands-on tutorial validation, throwaway projects, generated files, dependencies, local databases, and other experiment artifacts. Do not rely on files inside `sandbox/` as committed source material.

## Coding Style & Naming Conventions

Write notes in standard Markdown compatible with Obsidian. Use `[[Note Name]]` for internal links (Obsidian tracks these as bidirectional backlinks), `#tag` for tags, and YAML frontmatter (between `---` delimiters) only when metadata is useful. Prefer concise headings, short paragraphs, and fenced code blocks with a language label, for example ` ```bash `.

Use descriptive filenames. Existing files are mixed, but prefer lowercase words separated by hyphens for new notes, such as `laravel-deployment-checklist.md`. Keep project-specific config files under the relevant project folder, for example `01-projects/qadrlabs/`.

## Testing Guidelines

There is no automated test suite. Validate changes by checking Markdown rendering in Obsidian, confirming internal links resolve, and reviewing command snippets for accuracy before publishing or archiving notes.

## Commit & Pull Request Guidelines

Recent commits use short, imperative summaries such as `add draft`, `publish post`, and `move to inbox`. Follow that style: keep the subject concise, lowercase when natural, and focused on the content change.

Pull requests should describe the changed notes, explain any folder moves, and call out screenshots only when visual Obsidian rendering matters. Link related issues or tasks when available.

## Agent-Specific Instructions

Do not reorganize the PARA folders without a clear request. Avoid changing `.obsidian/workspace.json`. Preserve personal notes and Indonesian-language content unless editing for an explicit task.

Agents may create, read, modify, and delete files inside `sandbox/` while testing tutorials. Keep secrets out of this folder; use example credentials, placeholder values, or `.env.example` patterns instead of real `.env` values.

For qadrlabs.com article work, follow `.claude/commands/generate-artikel.md` as the project-local article guide. It defines the required English writing style, Laravel 13 conventions, article structure, testing expectations, and surgical-edit workflow.

## Video Tracking

Every motion-graphics video made by an agent (Claude Code or Codex), from any template, is tracked in this vault. The user checks status, file locations, and publish state in Vault Hub (`~/Sites/vault-hub`, page `/video`). Template paths, keys, and starter prompts live in `03-resources/video-templates.md`. Read it when the user asks for a video from the vault, and add a row there when a new template appears.

### Lifecycle

1. The user starts `claude` or `codex` in the vault or in a template folder and describes the video.
2. The agent picks the template (registry), creates the project folder the way that template's `AGENTS.md` says, and **immediately** creates the vault note with `status: in-progress` and `variants: []`, before research or scripting.
3. The agent follows the template's `AGENTS.md` until the video is rendered. When the session started in the vault, read the template's `AGENTS.md` explicitly; it is not loaded automatically.
4. After each final render, the agent adds or updates that file's entry in `variants` with `status: rendered`, updates the top-level `status`, and fills the note body.
5. The final report to the user names the vault note path and every MP4 path.
6. The user publishes and marks variants as published in Vault Hub. An agent only does this when the user explicitly asks and gives the URL.

### Note format

One note per video project: `01-projects/<brand>/video/YYYY-MM-DD-<slug>.md` (date = start date, slug = project folder name or episode slug).

```yaml
---
type: video
brand: qadrtech                # qadrtech | qadrlabs
title: Sistem KP — Promo & Portfolio
date: 2026-10-30
status: in-progress            # idea | in-progress | rendered | published (least finished variant)
template: qadrtech-promo       # key from 03-resources/video-templates.md
project_dir: ~/Projects/qadrtech-hq/videos/kp-management-system
generated_by: claude           # claude | codex
tags: [qadrtech, video, motion-graphics]
variants:
  - id: promo-id               # stable slug, unique in this note
    label: Promo (ID)
    path: ~/Projects/qadrtech-hq/videos/kp-management-system/out/sistem-kp-promo.mp4
    format: 1080x1920 30fps
    duration: 40               # seconds
    status: rendered           # in-progress | rendered | published
    published: []              # [{platform: instagram, url: https://..., date: 2026-11-01}]
---
```

Body: what the video is about, the source project or topic, links to the script and caption files (absolute `~/` paths), and short production notes (voice, trims, anything the user must re-check).

### Rules

- Before creating a note, search `01-projects/*/video/` for one with the same `project_dir` (and, for a shared repo, the same episode). Update it instead of creating a duplicate. A re-render or a new language goes into the same note as a new or updated variant.
- One variant per **final** MP4 (language, promo vs portfolio, voice version). Do not list stills, voice-over clips, contact sheets, or intermediate renders.
- Paths outside the vault use `~/`; paths inside the vault are relative to the vault root. Point `path` at the file that exists now; if the file is moved, update `path`.
- Top-level `status` is the least finished variant (`in-progress` < `rendered` < `published`). It stays `in-progress` while `variants` is empty.
- Never set `published` or add entries to `published` yourself. Write `published` in flow style on one line.
- Edit frontmatter in place, one line per field. Vault Hub edits the same lines, so do not reorder or reformat the frontmatter.
- Older notes that use a single `video_path` instead of `variants` are still read by Vault Hub. Convert them to `variants` when you touch them.

## Todo Boards

Todo boards live in `02-areas/todo/*.md` in Obsidian Kanban format (`## Lane` headings with `- [ ] card #tag 📅 YYYY-MM-DD [[note]]` items). Preserve the `%% kanban:settings` footer when editing.
