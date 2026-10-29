# Changelog

## 0.1.1 · 2026-10-29

Fixes to the bridge skills. To upgrade a project: `git -C ~/agent-skills fetch --tags && git -C ~/agent-skills checkout v0.1.1`, then run the installer again in the project and commit the changed files.

- **Handover commit:** the commit step now names the file (`git commit ... -- .bridge/HANDOVER.md`), so other staged changes stay out of the handover commit.
- **Bridge branch check:** `/bridge-handoff` says so before writing when the current branch is not a `bridge/<topic>` branch, and offers to create one.
- **Commit wording:** the `AGENTS.md` note no longer tells agents to commit on their own; it agrees with the skill, which commits or pushes only when asked.
- **Installer:** re-running the installer now replaces an older bridge note in `AGENTS.md` with the current one, and stops without changes if the note's end marker is missing.
- **Main branch:** both skills find the main branch from `origin/HEAD` instead of assuming `origin/main`; `promote.sh` is suggested with `--base` when it differs.
- **Checks:** both skills say where to find the project's quick checks, and the handover records which ones ran.
- **Takeover report:** `/bridge-takeover` reports in a fixed five-part shape.
- **Wording:** the broken-shared-code warning moved into the handover-writing step; the rules now give their reasons and are pinned identical in both skills by a test; the Git ownership advice is no longer specific to one setup; "Written by" takes a name or handle.

## 0.1.0 · 2026-10-21

First release.

- **Bridge pack:** `bridge-handoff` and `bridge-takeover` pass a branch's working context to another person, machine, or AI tool through `.bridge/HANDOVER.md`. `promote.sh` copies the finished work onto a clean branch without `.bridge/`.
- **Hub installers:** `install.sh` (bash, jq) and `install.js` (Node.js 16.7 or later) copy packs into a project, with `--list`, `--all`, `--packs-dir`, `--target`, and `--no-hook`.
- **Documentation:** a README with a quick start, a table of contents, "Git as a brain-state cache", a diagram, scenarios, a workflow table, and an FAQ; `llms.txt` summarises the repository for AI tools.
- **Tested so far:** Claude Code on Linux and WSL Ubuntu. Not yet run: Codex, Copilot, Gemini CLI, macOS, and Windows outside WSL.
- **Requirements:** Git 2.23 or later.
