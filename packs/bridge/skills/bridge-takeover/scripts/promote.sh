#!/bin/sh
# Copy a bridge branch's finished work onto a clean branch from main, without .bridge/.
# It stages the result and stops: committing and pushing stay with you.
# Exit codes: 0 staged and ready to commit, 1 refused or failed, 2 usage error.
set -eu

usage() {
  cat >&2 <<'EOF'
Usage: sh promote.sh <bridge-branch> [--into <branch>] [--base <ref>] [--check "<command>"]
  --into   name of the new branch (default: feature/<topic> for bridge/<topic>)
  --base   where the new branch starts (default: origin/main)
  --check  your project's checks, run after the copy; for example "npm test"
EOF
  exit 2
}
die() { echo "promote: $*" >&2; exit 1; }

source_branch=""
into=""
base="origin/main"
check=""
while [ $# -gt 0 ]; do
  case "$1" in
    --into)  [ $# -ge 2 ] || usage; into="$2"; shift 2 ;;
    --base)  [ $# -ge 2 ] || usage; base="$2"; shift 2 ;;
    --check) [ $# -ge 2 ] || usage; check="$2"; shift 2 ;;
    -h|--help) usage ;;
    -*) echo "promote: unknown option $1" >&2; usage ;;
    *) [ -z "$source_branch" ] || usage; source_branch="$1"; shift ;;
  esac
done
[ -n "$source_branch" ] || usage
[ -n "$into" ] || into="feature/${source_branch#bridge/}"

root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not inside a Git repository"
cd "$root" || die "cannot enter $root"

[ -z "$(git status --porcelain --untracked-files=no)" ] \
  || die "you have uncommitted changes; commit or stash them first"

# Fetch the base's remote when it has one (origin/main); a local base (main) is used as is.
base_remote="${base%%/*}"
if [ "$base_remote" != "$base" ] && git remote | grep -qx "$base_remote"; then
  git fetch --quiet "$base_remote" || die "could not fetch $base_remote"
fi
# The new branch is pushed where the bridge branch lives (origin in a fork, not upstream).
remote="$(git config "branch.$source_branch.remote" || echo origin)"
if ! git remote | grep -qx "$remote"; then
  remote="<remote>"
elif [ "$remote" != "$base_remote" ]; then
  git fetch --quiet "$remote" \
    || echo "promote: could not fetch $remote; checking $source_branch against what was fetched last" >&2
fi

git rev-parse -q --verify "$source_branch^{commit}" >/dev/null || die "no branch named $source_branch"
# Someone else may have pushed last: promoting a local copy that lacks their commits would drop them.
# A branch started from origin/main tracks origin/main; main moving on is not missing work.
upstream="$(git rev-parse --symbolic-full-name "$source_branch@{u}" 2>/dev/null)" || upstream=""
if [ "${upstream#refs/remotes/*/}" = "${base#"$base_remote"/}" ]; then upstream=""; fi
if [ -n "$upstream" ] && git rev-parse -q --verify "$upstream" >/dev/null \
  && ! git merge-base --is-ancestor "$upstream" "$source_branch"; then
  die "$source_branch is missing commits from ${upstream#refs/remotes/}. Get them first: git switch $source_branch && git pull --ff-only (merge or rebase instead if both sides have new commits)"
fi
git rev-parse -q --verify "$base^{commit}" >/dev/null || die "no base named $base"
! git rev-parse -q --verify "refs/heads/$into" >/dev/null \
  || die "branch $into already exists; pick another name with --into"

patch="$(mktemp)"
trap 'rm -f "$patch"' EXIT
git diff --binary "$base...$source_branch" -- . ':(exclude).bridge' > "$patch"
[ -s "$patch" ] || die "$source_branch has no changes to promote outside .bridge/"

# The undo drops the staged copy first; otherwise switching back can refuse to overwrite it.
if start="$(git symbolic-ref -q --short HEAD)"; then
  back="git switch $start"
else
  back="git switch --detach $(git rev-parse HEAD)"
fi
git switch --quiet --no-track -c "$into" "$base"
undo="git reset --quiet --hard && $back && git branch -D $into"
git apply --index "$patch" || die "the changes did not apply cleanly. To undo: $undo"

! git diff --cached --quiet || die "nothing was staged. To undo: $undo"
[ -z "$(git diff --cached --name-only -- .bridge)" ] || die ".bridge/ was staged; do not commit. To undo: $undo"

echo "Staged on $into:"
git diff --cached --stat

if [ -n "$check" ]; then
  echo "Running: $check"
  sh -c "$check" || die "the check failed. Fix it on $into, or undo: $undo"
fi

cat <<EOF

Ready. Review with 'git diff --cached', then:
  git commit -m "<what the work does>"
  git push -u $remote $into    # open the pull request from this branch
After it is merged, delete $source_branch locally and on the remote.
EOF
