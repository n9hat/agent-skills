---
name: bridge-takeover
description: Continue a branch that someone else, or you on another machine, was working on. Reads .bridge/HANDOVER.md, or rebuilds intent from Git, and proposes next steps. Use for a "bridge takeover", /bridge-takeover, or when .bridge/HANDOVER.md is present.
---

# Bridge Takeover

Continue someone else's work, or your own from another machine, without losing momentum, whatever tool or workflow either side uses.

## Steps

1. **Sync safely.** Run `git fetch --prune` and `git status`; report whether the branch is behind or ahead of its upstream, and any local branch whose upstream is gone. If there are local changes, ask before pulling, resetting, or switching branches. If Git refuses the repository (for example "dubious ownership" on a `\\wsl.localhost` path), run Git inside that environment, such as `wsl.exe -- git ...`, rather than changing global Git config.
2. **Read the handover, if there is one.** Check `.bridge/HANDOVER.md` against the repo:
   - Commits after its "Last commit" are work done since the handoff; summarise them. The `bridge:` commit that added the handover itself is expected, not drift.
   - Do the files it lists exist? Do its push state and "Current state" still hold? Run the project's quick, known checks.
3. **Otherwise, rebuild the intent** from `git log -10 --stat`, the diffs, the branch name, issue references in commit messages, and TODOs in changed files. Label everything you infer as "inferred".
4. **Check against the contracts** the handover lists or that you find.
5. **Report back:** where things stand in a few lines; what no longer matches the repo; the next three steps; questions for the previous owner. Express the plan in the user's own workflow (tasks, beads, a spec change); if you cannot tell which, ask.
6. **Wait for agreement.** Do not change code until the user agrees with the plan.
7. **Keep the cache fresh.** Before the user stops, suggest a new bridge handoff. When the work is finished, suggest promoting it to a clean branch so `.bridge/` never reaches the main branch:
   `git switch -c <feature> origin/main && git diff --binary origin/main...<bridge-branch> -- . ':(exclude).bridge' | git apply --index`.

## Rules

- **Contracts first.** Shared API specs and interface or type files win over logic on the feature branch.
- **Never push a broken shared module.** If shared code fails, keep the fix or a stand-in (test double) inside your own area until it is resolved.
- **Tool-neutral.** Judge the work by whether it builds and passes its tests, not by which tool or method produced it.
