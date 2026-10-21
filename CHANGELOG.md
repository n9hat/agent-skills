# Changelog

## 0.1.0 · 2026-10-21

First release.

- **Bridge pack:** `bridge-handoff` and `bridge-takeover` pass a branch's working context to another person, machine, or AI tool through `.bridge/HANDOVER.md`. `promote.sh` copies the finished work onto a clean branch without `.bridge/`.
- **Hub installers:** `install.sh` (bash, jq) and `install.js` (Node.js 16.7 or later) copy packs into a project, with `--list`, `--all`, `--packs-dir`, `--target`, and `--no-hook`.
- **Tested so far:** Claude Code on Linux and WSL Ubuntu. Not yet run: Codex, Copilot, Gemini CLI, macOS, and Windows outside WSL.
- **Requirements:** Git 2.23 or later.
