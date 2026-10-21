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

echo "bridge: passed: $pass  failed: $fail"
[ "$fail" -eq 0 ]
