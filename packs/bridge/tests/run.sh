#!/usr/bin/env bash
# Tests for the bridge pack: its skills and its extras (AGENTS.md note, Claude Code hook),
# installed through the hub's installers.
# Usage: packs/bridge/tests/run.sh        (needs bash, node and jq)
set -u

for tool in node jq; do
  command -v "$tool" >/dev/null 2>&1 || { echo "packs/bridge/tests/run.sh needs $tool; install it and run again." >&2; exit 2; }
done

PACK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HUB="$(cd "$PACK/../.." && pwd)"
SKILLS=(bridge-handoff bridge-takeover)
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $desc"; fi
}

# Install the bridge pack with one hub installer kind ("sh" or "js") inside a target dir.
run_installer() {
  local kind="$1" target="$2"; shift 2
  case "$kind" in
    sh) (cd "$target" && bash "$HUB/install.sh" "$@" bridge) ;;
    js) (cd "$target" && node "$HUB/install.js" "$@" bridge) ;;
  esac
}

fails() { ! "$@"; }

bridge_hook_count() {
  jq '[.hooks.SessionStart[]?.hooks[]? | select(.command | contains(".bridge/HANDOVER.md"))] | length' "$1"
}

new_target() {
  local t="$WORK/$1"
  mkdir -p "$t"
  echo "$t"
}

# --- Skill files -------------------------------------------------------------
for skill in "${SKILLS[@]}"; do
  f="$PACK/skills/$skill/SKILL.md"
  check "$skill: SKILL.md exists" test -f "$f"
  check "$skill: frontmatter name matches folder" grep -qx "name: $skill" "$f"
  check "$skill: has a description" grep -q '^description: ' "$f"
done

template() { sed -n '/<!-- bridge-template:start -->/,/<!-- bridge-template:end -->/p' "$1"; }
check "HANDOVER template present in bridge-handoff" test -n "$(template "$PACK/skills/bridge-handoff/SKILL.md")"
check "HANDOVER template kept in one place" test -z "$(template "$PACK/skills/bridge-takeover/SKILL.md")"

# --- Installed through the hub ----------------------------------------------
for kind in sh js; do
  # Fresh install
  t="$(new_target "$kind-fresh")"
  check "$kind fresh: installer exits 0" run_installer "$kind" "$t"
  for dir in .agents/skills .claude/skills; do
    for skill in "${SKILLS[@]}"; do
      check "$kind fresh: $dir/$skill matches source" diff -r "$PACK/skills/$skill" "$t/$dir/$skill"
    done
  done
  check "$kind fresh: AGENTS.md has bridge note" grep -qF '<!-- bridge:begin -->' "$t/AGENTS.md"
  check "$kind fresh: settings.json has one bridge hook" test "$(bridge_hook_count "$t/.claude/settings.json")" = 1

  # Re-run is idempotent
  run_installer "$kind" "$t" >/dev/null 2>&1
  check "$kind rerun: one AGENTS.md note" test "$(grep -cF '<!-- bridge:begin -->' "$t/AGENTS.md")" = 1
  check "$kind rerun: still one bridge hook" test "$(bridge_hook_count "$t/.claude/settings.json")" = 1

  # Existing files are preserved
  t="$(new_target "$kind-existing")"
  mkdir -p "$t/.claude"
  printf '# Team rules\nKeep it tidy.\n' > "$t/AGENTS.md"
  echo '{"model":"opus","hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"echo hi"}]}]}}' > "$t/.claude/settings.json"
  check "$kind existing: installer exits 0" run_installer "$kind" "$t"
  check "$kind existing: AGENTS.md content kept" grep -qx 'Keep it tidy.' "$t/AGENTS.md"
  check "$kind existing: other settings kept" test "$(jq -r .model "$t/.claude/settings.json")" = opus
  check "$kind existing: other hook kept" \
    test "$(jq '[.hooks.SessionStart[].hooks[] | select(.command == "echo hi")] | length' "$t/.claude/settings.json")" = 1
  check "$kind existing: bridge hook added" test "$(bridge_hook_count "$t/.claude/settings.json")" = 1

  # Invalid settings.json is refused and left untouched
  t="$(new_target "$kind-invalid")"
  mkdir -p "$t/.claude"
  echo '{ not json' > "$t/.claude/settings.json"
  check "$kind invalid: installer exits nonzero" fails run_installer "$kind" "$t"
  check "$kind invalid: settings.json unchanged" grep -qx '{ not json' "$t/.claude/settings.json"

  # --no-hook reaches the pack: skips settings.json, keeps the note
  t="$(new_target "$kind-nohook")"
  check "$kind --no-hook: installer exits 0" run_installer "$kind" "$t" --no-hook
  check "$kind --no-hook: no settings.json" test ! -e "$t/.claude/settings.json"
  check "$kind --no-hook: AGENTS.md note still added" grep -qF '<!-- bridge:begin -->' "$t/AGENTS.md"

  # --target reaches the pack: extras land in the target, not the cwd
  t="$(new_target "$kind-target")"
  check "$kind --target: installer exits 0" run_installer "$kind" "$WORK" --target "$t"
  check "$kind --target: AGENTS.md lands in target" test -f "$t/AGENTS.md"
  check "$kind --target: hook lands in target" test -f "$t/.claude/settings.json"
  check "$kind --target: nothing written to cwd" test ! -e "$WORK/AGENTS.md"
done

# --- promote.sh: copy a bridge branch's work onto a clean branch --------------
PROMOTE="$PACK/skills/bridge-takeover/scripts/promote.sh"
check "promote.sh exists" test -f "$PROMOTE"

# Keep the user's own Git config (hooks, signing, aliases) out of the fixtures.
export GIT_CONFIG_GLOBAL="$WORK/gitconfig" GIT_CONFIG_NOSYSTEM=1
git config --global user.name Test
git config --global user.email test@example.com
git config --global init.defaultBranch main

# A clone of a fresh origin, with main pushed and bridge/topic carrying one work
# commit and one handover commit.
new_repo() {
  local r="$WORK/repo-$1"
  git init -q --bare "$r.git"
  git clone -q "$r.git" "$r" 2>/dev/null
  (
    cd "$r" || exit 1
    echo base > base.txt && mkdir sub && echo sub > sub/keep.txt
    git add -A && git commit -qm base && git push -q origin main
    git switch -qc bridge/topic
    echo work > work.txt && git add work.txt && git commit -qm work
    mkdir .bridge && echo handover > .bridge/HANDOVER.md
    git add .bridge && git commit -qm "bridge: handoff"
    git switch -q main
  )
  echo "$r"
}
promote() { (cd "$1" && shift && sh "$PROMOTE" "$@"); }
branch_exists() { git -C "$1" rev-parse -q --verify "refs/heads/$2" >/dev/null; }
staged() { git -C "$1" diff --cached --name-only; }
current() { git -C "$1" branch --show-current; }

# Normal promotion: work staged on feature/topic, handover left out
r="$(new_repo ok)"
out="$(promote "$r" bridge/topic 2>&1)"; code=$?
check "promote: exits 0" test "$code" = 0
check "promote: switches to feature/topic" test "$(current "$r")" = feature/topic
check "promote: stages the work" grep -qx work.txt <<<"$(staged "$r")"
check "promote: leaves .bridge out" test -z "$(staged "$r" | grep '^\.bridge/')"
check "promote: starts from origin/main" test "$(git -C "$r" rev-parse HEAD)" = "$(git -C "$r" rev-parse origin/main)"
check "promote: prints the commit step" grep -q 'git commit' <<<"$out"
check "promote: does not commit" test "$(git -C "$r" rev-list --count HEAD)" = 1

# Work merged into main after the branch left is kept, not undone
r="$(new_repo moved)"
(cd "$r" && echo later > later.txt && git add later.txt && git commit -qm later && git push -q origin main)
promote "$r" bridge/topic >/dev/null 2>&1
check "promote moved main: later work kept" test -f "$r/later.txt"
check "promote moved main: bridge work staged" grep -qx work.txt <<<"$(staged "$r")"

# --into names the branch; works from a subdirectory
r="$(new_repo into)"
check "promote --into: exits 0 from a subdirectory" promote "$r/sub" bridge/topic --into release/topic
check "promote --into: uses the given name" test "$(current "$r")" = release/topic

# --check runs after the apply, and a failure stops with an error
r="$(new_repo check-ok)"
check "promote --check: passing check exits 0" promote "$r" bridge/topic --check "test -f work.txt"
r="$(new_repo check-fail)"
check "promote --check: failing check exits nonzero" fails promote "$r" bridge/topic --check "exit 3"
check "promote --check: failing check keeps branch to inspect" test "$(current "$r")" = feature/topic

# Refusals: nothing is created
r="$(new_repo dirty)"
echo edit >> "$r/base.txt"
check "promote dirty: refused" fails promote "$r" bridge/topic
check "promote dirty: no branch created" fails branch_exists "$r" feature/topic

r="$(new_repo unknown)"
check "promote unknown branch: refused" fails promote "$r" bridge/nope
check "promote unknown branch: no branch created" fails branch_exists "$r" feature/nope

r="$(new_repo exists)"
git -C "$r" branch feature/topic
check "promote existing feature branch: refused" fails promote "$r" bridge/topic
check "promote existing feature branch: still on main" test "$(current "$r")" = main

r="$(new_repo empty)"
(cd "$r" && git switch -qc bridge/only-handover && mkdir -p .bridge && echo h > .bridge/HANDOVER.md \
  && git add .bridge && git commit -qm "bridge: handoff" && git switch -q main)
check "promote handover only: refused" fails promote "$r" bridge/only-handover
check "promote handover only: no branch created" fails branch_exists "$r" feature/only-handover

r="$(new_repo usage)"
promote "$r" >/dev/null 2>&1; code=$?
check "promote no arguments: exits 2" test "$code" = 2
check "promote no arguments: shows usage" grep -q 'Usage: sh promote.sh' <<<"$(promote "$r" 2>&1)"

# A local --base still prints a push to the real remote
r="$(new_repo local-base)"
out="$(promote "$r" bridge/topic --base main 2>&1)"
check "promote --base main: push hint names origin" grep -q 'git push -u origin feature/topic' <<<"$out"

echo "bridge: passed: $pass  failed: $fail"
[ "$fail" -eq 0 ]
