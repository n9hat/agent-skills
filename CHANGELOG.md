# Changelog

## Unreleased

- **Documentation:** the README opens with a quick start and a table of contents, and adds "Git as a brain-state cache", a diagram, scenarios, a workflow table, and an FAQ. New `llms.txt` summarises the repository for AI tools. The bridge README gains a table of contents. The away (sick-leave) scenario is renamed in the READMEs and the handover template.

## 0.1.0 · 2026-10-21

First release.

- **Bridge pack:** `bridge-handoff` and `bridge-takeover` pass a branch's working context to another person, machine, or AI tool through `.bridge/HANDOVER.md`. `promote.sh` copies the finished work onto a clean branch without `.bridge/`.
- **Hub installers:** `install.sh` (bash, jq) and `install.js` (Node.js 16.7 or later) copy packs into a project, with `--list`, `--all`, `--packs-dir`, `--target`, and `--no-hook`.
- **Tested so far:** Claude Code on Linux and WSL Ubuntu. Not yet run: Codex, Copilot, Gemini CLI, macOS, and Windows outside WSL.
- **Requirements:** Git 2.23 or later.
