---
name: bridge-handoff
description: Write .bridge/HANDOVER.md so another person, or you on another machine, can continue this branch with any AI tool or none. Use only for a "bridge handoff" or /bridge-handoff, not a generic handoff or chat summary.
---

# Bridge Handoff

Record where this branch stands, in plain language, so whoever continues it, with whatever tool or workflow, can carry on without asking you.

## Steps

1. **Check the branch.** The handover belongs on a bridge branch, `bridge/<topic>`, because that branch never merges straight into the main branch; on any other branch, `.bridge/` can reach it in a merge. If the current branch is not a bridge branch, or HEAD is detached, say so before writing anything and offer `git switch -c bridge/<topic>`, which keeps uncommitted work. Carry on where you are only if the user says so.
2. **Settle the work first.** The handover describes the branch as it will be pushed, so uncommitted work should be committed before it is written, in commits that do not touch `.bridge/`. If there is uncommitted work, ask the user to commit it (or commit it if they ask); whatever they choose to leave uncommitted goes under "Local only".
3. **Inspect the branch.** Run `git fetch --quiet` so the comparison is current. Find the main branch: `git symbolic-ref --short refs/remotes/origin/HEAD`, usually `origin/main`; if that is not set, `git ls-remote --symref origin HEAD` prints `ref: refs/heads/<name>`, so use `origin/<name>`; below it is `<main>`. Then run `git status -sb`, `git diff` (staged and unstaged), `git stash list`, and for the whole branch `git log --oneline <main>..HEAD` and `git diff --stat <main>...HEAD`.
4. **Read the previous handover**, if any. Keep decisions in force, open questions and unfinished steps; drop what is done or answered (an answer that shaped the work becomes a decision).
5. **Find the contracts.** API specs, shared types or interfaces, schemas, plans, ADRs. Reference them by path; do not copy them.
6. **State the truth about the build.** Run the project's quick checks: the ones its README, AGENTS.md or CLAUDE.md names, or else the test and lint commands in its package scripts, Makefile or CI config. Record which ones you ran and the result, or write "not run".
7. **Write `.bridge/HANDOVER.md`** from the template below, replacing the previous version: a snapshot of now, not a log, about one screen long.
   - Plain language; explain workflow jargon (beads, tickets, spec IDs) or point to the file.
   - Record decisions with their reason, open and answered questions, and anything that so far exists only in your head. Lasting decisions belong in the project's docs; point to them.
   - If shared code is broken, start "Current state" with that, so the next person does not build on it.
   - No secrets or personal data: name environment variables, never their values. Your name or handle in "Written by" is fine.
8. **Hand it back to the user.** Show the file, repeat any broken-shared-code warning, and give the commit steps. The handover gets a commit that touches only `.bridge/`, so it can be left out when the work moves to the main branch; the path after `--` keeps anything else that is staged out of it:
   `git add .bridge/HANDOVER.md && git commit -m "bridge: handoff" -- .bridge/HANDOVER.md && git push`.
   The first time, while the branch has no upstream yet, push with `git push -u origin HEAD` instead. Until it is pushed, nobody else receives it. Commit or push yourself only if the user asks.
9. **If the work is finished** rather than paused, suggest promoting it instead of handing it off: `promote.sh`, in the bridge-takeover skill's `scripts/` folder, copies the work onto a clean branch without `.bridge/`.

## Rules

- **Contracts first.** When the branch's code and a shared contract (API spec, interface or type file) disagree, change the code, not the contract, unless the user agrees: other people build against the contract.
- **Never push a broken shared module.** Others pull shared code straight away, so a break there stops them too. If shared code fails, keep the fix or a stand-in (test double) inside your own area until it is resolved.
- **Tool-neutral.** Judge the work by whether it builds and passes its tests, not by which tool or method produced it: the next person may use a different one.

## Template

<!-- bridge-template:start -->
```markdown
# Bridge Handover

- Branch: <branch> · Last commit: <short sha> <subject>
- Written by: <name or handle> · <date, time and timezone>
- Scenario: <timezone handoff | away (sick-leave) cover | device switch | other>
- Tools used: <for example "Claude Code + a task-graph workflow", "Codex + specs", "none">

## 1. Goal and boundaries
- Objective: <what this branch is for>
- Contracts: <paths to API specs, shared types, schemas, plans>
- Out of scope: <what not to touch>

## 2. Code footprint
- Created: <paths>
- Modified shared modules: <paths>
- Current state: <checks run and their result, for example "npm test: builds; integration tests 4 and 5 fail">
- Local only: <uncommitted files, stashes, environment variable names needed, local data or services; or "none">

## 3. Decisions and open questions
- Decided: <decision> (reason: <why>)
- Open: <question> (who can answer: <name>)

## 4. Next steps
1. <smallest next task>
2. <next task>
3. <next task>
```
<!-- bridge-template:end -->
