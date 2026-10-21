#!/usr/bin/env bash
# Tests for the hub's installers (install.sh, install.js), using small fixture packs.
# Usage: tests/installer.sh        (needs bash and node)
set -u

command -v node >/dev/null 2>&1 || { echo "tests/installer.sh needs node; install it and run again." >&2; exit 2; }

HUB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $desc"; fi
}

run_installer() {
  local kind="$1" cwd="$2"; shift 2
  case "$kind" in
    sh) (cd "$cwd" && bash "$HUB/install.sh" "$@") ;;
    js) (cd "$cwd" && node "$HUB/install.js" "$@") ;;
  esac
}

fails() { ! "$@"; }

new_target() {
  local t="$WORK/targets/$1"
  mkdir -p "$t"
  echo "$t"
}

skill() {
  mkdir -p "$1"
  printf -- '---\nname: %s\ndescription: test skill\n---\n' "${1##*/}" > "$1/SKILL.md"
}

# --- Fixture packs -----------------------------------------------------------
EXTRA="$WORK/extra"
skill "$EXTRA/demo/skills/demo-skill"
mkdir -p "$EXTRA/demo/skills/not-a-skill"
skill "$EXTRA/extras/skills/extras-skill"
printf '%s\n' 'shift; echo "$@" > "$1/extras-sh"' > "$EXTRA/extras/install.sh"
printf '%s\n' 'const a = process.argv.slice(2); require("fs").writeFileSync(a[1] + "/extras-js", a.join(" ") + "\n");' > "$EXTRA/extras/install.js"

ONE_SIDED="$WORK/one-sided"
skill "$ONE_SIDED/sh-only/skills/sh-only-skill"
echo 'true' > "$ONE_SIDED/sh-only/install.sh"
skill "$ONE_SIDED/js-only/skills/js-only-skill"
echo '' > "$ONE_SIDED/js-only/install.js"

CLASH="$WORK/clash"
skill "$CLASH/bridge/skills/fake-bridge"

for kind in sh js; do
  # --list
  out="$(run_installer "$kind" "$WORK" --list)"
  check "$kind --list: shows bridge" grep -q "^bridge	$HUB/packs/bridge$" <<<"$out"
  out="$(run_installer "$kind" "$WORK" --packs-dir "$EXTRA" --list)"
  check "$kind --list: shows packs from --packs-dir" grep -q '^demo	' <<<"$out"
  out="$(run_installer "$kind" "$WORK" --packs-dir "$CLASH" --list)"
  check "$kind --list: built-in pack wins a name clash" grep -q "^bridge	$HUB/packs/bridge$" <<<"$out"

  # One pack without its own installer
  t="$(new_target "$kind-demo")"
  check "$kind demo: installer exits 0" run_installer "$kind" "$t" --packs-dir "$EXTRA" demo
  for dir in .agents/skills .claude/skills; do
    check "$kind demo: $dir/demo-skill matches source" diff -r "$EXTRA/demo/skills/demo-skill" "$t/$dir/demo-skill"
  done
  check "$kind demo: folder without SKILL.md skipped" test ! -e "$t/.claude/skills/not-a-skill"
  check "$kind demo: no extras written" test ! -e "$t/AGENTS.md"

  # Several packs; the pack's own installer gets --target and --no-hook
  t="$(new_target "$kind-several")"
  check "$kind several: installer exits 0" run_installer "$kind" "$t" --packs-dir "$EXTRA" --no-hook demo extras
  check "$kind several: first pack installed" test -f "$t/.claude/skills/demo-skill/SKILL.md"
  check "$kind several: second pack installed" test -f "$t/.claude/skills/extras-skill/SKILL.md"
  check "$kind several: pack installer got --no-hook" grep -q -- '--no-hook' "$t/extras-$kind"

  # --all
  t="$(new_target "$kind-all")"
  check "$kind --all: installer exits 0" run_installer "$kind" "$t" --packs-dir "$EXTRA" --all --no-hook
  check "$kind --all: built-in pack installed" test -f "$t/.claude/skills/bridge-takeover/SKILL.md"
  check "$kind --all: extra pack installed" test -f "$t/.claude/skills/demo-skill/SKILL.md"

  # --target from another directory
  t="$(new_target "$kind-target")"
  mkdir -p "$WORK/cwd-$kind"
  check "$kind --target: installer exits 0" run_installer "$kind" "$WORK/cwd-$kind" --packs-dir "$EXTRA" --target "$t" extras
  check "$kind --target: skills land in target" test -f "$t/.agents/skills/extras-skill/SKILL.md"
  check "$kind --target: pack installer got the target" test -f "$t/extras-$kind"
  check "$kind --target: nothing written to cwd" test -z "$(ls -A "$WORK/cwd-$kind")"

  # Errors
  t="$(new_target "$kind-errors")"
  check "$kind no pack named: exits nonzero" fails run_installer "$kind" "$t"
  check "$kind unknown pack: exits nonzero" fails run_installer "$kind" "$t" --packs-dir "$EXTRA" demo nope
  check "$kind unknown pack: nothing installed" test -z "$(ls -A "$t")"
  check "$kind bad option: exits nonzero" fails run_installer "$kind" "$t" --bogus bridge
  check "$kind missing --packs-dir: exits nonzero" fails run_installer "$kind" "$t" --packs-dir "$WORK/nope" --list
done

# A pack installer for only one shell is run by that installer and refused by the other.
t="$(new_target sh-one-sided)"
check "sh: runs a bash-only pack" run_installer sh "$t" --packs-dir "$ONE_SIDED" sh-only
check "sh: refuses a Node-only pack" fails run_installer sh "$t" --packs-dir "$ONE_SIDED" js-only
check "sh: refused pack not copied" test ! -e "$t/.claude/skills/js-only-skill"
t="$(new_target js-one-sided)"
check "js: runs a Node-only pack" run_installer js "$t" --packs-dir "$ONE_SIDED" js-only
check "js: refuses a bash-only pack" fails run_installer js "$t" --packs-dir "$ONE_SIDED" sh-only
check "js: refused pack not copied" test ! -e "$t/.claude/skills/sh-only-skill"

echo "installer: passed: $pass  failed: $fail"
[ "$fail" -eq 0 ]
