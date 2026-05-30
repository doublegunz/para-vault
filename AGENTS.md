# Repository Guidelines

## Project Structure & Module Organization

This repository is an Obsidian vault organized with the PARA method. Content is Markdown-first and should remain easy to browse in Obsidian.

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

Write notes in standard Markdown compatible with Obsidian. Use `[[Note Name]]` for internal links, `#tag` for tags, and YAML frontmatter only when metadata is useful. Prefer concise headings, short paragraphs, and fenced code blocks with a language label, for example ` ```bash `.

Use descriptive filenames. Existing files are mixed, but prefer lowercase words separated by hyphens for new notes, such as `laravel-deployment-checklist.md`. Keep project-specific config files under the relevant project folder, for example `01-projects/qadrlabs/`.

## Testing Guidelines

There is no automated test suite. Validate changes by checking Markdown rendering in Obsidian, confirming internal links resolve, and reviewing command snippets for accuracy before publishing or archiving notes.

## Commit & Pull Request Guidelines

Recent commits use short, imperative summaries such as `add draft`, `publish post`, and `move to inbox`. Follow that style: keep the subject concise, lowercase when natural, and focused on the content change.

Pull requests should describe the changed notes, explain any folder moves, and call out screenshots only when visual Obsidian rendering matters. Link related issues or tasks when available.

## Agent-Specific Instructions

Do not reorganize the PARA folders without a clear request. Avoid changing `.obsidian/workspace.json`. Preserve personal notes and Indonesian-language content unless editing for an explicit task.

Agents may create, read, modify, and delete files inside `sandbox/` while testing tutorials. Keep secrets out of this folder; use example credentials or `.env.example` patterns instead of real `.env` values.

For qadrlabs.com article work, follow `.claude/commands/generate-artikel.md` as the project-local article guide. It defines the required English writing style, Laravel 13 conventions, article structure, testing expectations, and surgical-edit workflow.
