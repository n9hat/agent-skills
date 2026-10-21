---
name: bridge-handoff
description: Write .bridge/HANDOVER.md so another person, or you on another machine, can continue this branch with any AI tool or none. Use only for a "bridge handoff" or /bridge-handoff, not a generic handoff or chat summary.
---

# Bridge Handoff

Record where this branch stands, in plain language, so whoever continues it, with whatever tool or workflow, can carry on without asking you.

## Steps

1. **Inspect the branch.** `git status -sb`, `git diff` (staged and unstaged), `git stash list`, and for the whole branch `git log --oneline origin/main..HEAD` and `git diff --stat origin/main...HEAD`. Record the push state as it really is.
2. **Read the previous handover**, if any. Keep decisions in force, open questions and unfinished steps; drop what is done or answered (an answer that shaped the work becomes a decision).
3. **Find the contracts.** API specs, shared types or interfaces, schemas, plans, ADRs. Reference them by path; do not copy them.
4. **State the truth about the build.** Run the project's quick, known checks and record the result, or write "not run".
5. **Write `.bridge/HANDOVER.md`** from the template below, replacing the previous version: a snapshot of now, not a log, about one screen long.
   - Plain language; explain workflow jargon (beads, tickets, spec IDs) or point to the file.
   - Record decisions with their reason, open and answered questions, and anything that so far exists only in your head. Lasting decisions belong in the project's docs; point to them.
   - No secrets or personal data: name environment variables, never their values.
6. **Hand it back to the user.** Show the file. Uncommitted work goes in its own commit(s) first; the handover then gets a commit that touches only `.bridge/`, so it can be left out when the work moves to the main branch:
   `git add .bridge/HANDOVER.md && git commit -m "bridge: handoff" && git push`.
   If anything is still unpushed, say so: until it is pushed, nobody else receives it. Do not commit or push yourself unless the user asks.
7. **Warn about broken shared code** in "Current state" and in your reply.

## Rules

- **Contracts first.** Shared API specs and interface or type files win over logic on the feature branch.
- **Never push a broken shared module.** If shared code fails, keep the fix or a stand-in (test double) inside your own area until it is resolved.
- **Tool-neutral.** Judge the work by whether it builds and passes its tests, not by which tool or method produced it.

## Template

<!-- bridge-template:start -->
```markdown
# Bridge Handover

- Branch: <branch> · Last commit: <short sha> <subject> · Pushed: <yes | no>
- Written by: <name> · <date, time and timezone>
- Scenario: <timezone handoff | sick-leave cover | device switch | other>
- Tools used: <for example "Claude Code + a task-graph workflow", "Codex + specs", "none">

## 1. Goal and boundaries
- Objective: <what this branch is for>
- Contracts: <paths to API specs, shared types, schemas, plans>
- Out of scope: <what not to touch>

## 2. Code footprint
- Created: <paths>
- Modified shared modules: <paths>
- Current state: <for example "builds; integration tests 4 and 5 fail">
- Local only: <uncommitted files, unpushed commits, stashes, environment variable names needed, local data or services; or "none">

## 3. Decisions and open questions
- Decided: <decision> (reason: <why>)
- Open: <question> (who can answer: <name>)

## 4. Next steps
1. <smallest next task>
2. <next task>
3. <next task>
```
<!-- bridge-template:end -->
