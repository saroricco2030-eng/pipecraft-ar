#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# scan-orphan-fixes.sh — detect [fix] commits on branches that
# have not reached `main` (or configured base).
#
# Portable: pure git, works on Linux / macOS / Windows git-bash /
# GitHub Actions. Zero dependencies beyond git.
#
# Usage:
#   ./tools/scan-orphan-fixes.sh                  # default main
#   MAIN_BRANCH=master ./tools/scan-orphan-fixes.sh
#   ./tools/scan-orphan-fixes.sh --json           # machine-readable
#   ./tools/scan-orphan-fixes.sh --remote         # scan remote too
#
# Exit codes:
#   0 — no orphans detected
#   1 — orphans present (CI: fail, local: review)
#   2 — configuration error
#
# Reference: docs/BRANCH_WORKFLOW.md
# ──────────────────────────────────────────────────────────────
set -euo pipefail

MAIN_BRANCH="${MAIN_BRANCH:-main}"
SCAN_REMOTE=0
OUTPUT_JSON=0

for arg in "$@"; do
  case "$arg" in
    --json)    OUTPUT_JSON=1 ;;
    --remote)  SCAN_REMOTE=1 ;;
    --help|-h)
      sed -n '1,25p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Unknown arg: $arg" >&2
      exit 2
      ;;
  esac
done

# Verify we are in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "ERROR: not in a git repository" >&2
  exit 2
fi

# Verify main exists locally or on remote
if ! git show-ref --verify --quiet "refs/heads/${MAIN_BRANCH}" \
   && ! git show-ref --verify --quiet "refs/remotes/origin/${MAIN_BRANCH}"; then
  echo "ERROR: base branch '${MAIN_BRANCH}' not found locally or on origin" >&2
  echo "Hint: set MAIN_BRANCH=master or run 'git fetch origin' first" >&2
  exit 2
fi

# Pick the freshest view of main
if git show-ref --verify --quiet "refs/remotes/origin/${MAIN_BRANCH}"; then
  BASE_REF="origin/${MAIN_BRANCH}"
else
  BASE_REF="${MAIN_BRANCH}"
fi

# Gather branches to scan
if [ "$SCAN_REMOTE" -eq 1 ]; then
  BRANCHES=$(git branch -r \
    | grep -v -E "HEAD|${MAIN_BRANCH}\$" \
    | sed 's/^[ *]*//' \
    | sort -u)
else
  BRANCHES=$(git for-each-ref --format='%(refname:short)' \
    refs/heads/ refs/remotes/origin/ \
    | grep -v -E "^(origin/)?(${MAIN_BRANCH}|HEAD)\$" \
    | sort -u)
fi

# Apply .orphan-fix-ignore filter.
# Squash-merge and rebase-merge erase patch identity, so git can't
# automatically tell that a branch's individual commits have been
# absorbed into main via squash. The ignore file is the portable
# escape hatch: list branch names or globs (one per line, # comments).
# Repo root location is used (git rev-parse --show-toplevel).
IGNORE_FILE="$(git rev-parse --show-toplevel 2>/dev/null)/.orphan-fix-ignore"
if [ -f "$IGNORE_FILE" ]; then
  filtered=""
  while IFS= read -r branch; do
    skip=0
    while IFS= read -r pattern; do
      # Strip comments + trim whitespace
      pattern="${pattern%%#*}"
      pattern="$(echo "$pattern" | xargs)"
      [ -z "$pattern" ] && continue
      # Glob match against the branch name. Handles both local and
      # origin/ prefixed forms by stripping the leading 'origin/' for
      # comparison if the pattern doesn't mention it.
      if [[ "$branch" == $pattern ]] || [[ "${branch#origin/}" == $pattern ]]; then
        skip=1
        break
      fi
    done < "$IGNORE_FILE"
    [ $skip -eq 0 ] && filtered="$filtered$branch"$'\n'
  done <<< "$BRANCHES"
  BRANCHES="$filtered"
fi

# The regex catches both bracket-style [fix] and Conventional Commits fix:
# at the start of the subject line.
FIX_REGEX='^[0-9a-f]+ (\[fix\]|fix(\([^)]+\))?:|hotfix:)'

total_orphans=0
first_branch=1

if [ "$OUTPUT_JSON" -eq 1 ]; then
  printf '{"base":"%s","branches":[' "$BASE_REF"
fi

for branch in $BRANCHES; do
  # Commits on branch not in base. `-E` for extended regex; skip WIP.
  orphans=$(git log --oneline "$branch" "^${BASE_REF}" 2>/dev/null \
    | grep -E "$FIX_REGEX" \
    | grep -vE '\[wip\]' \
    || true)

  count=$(printf '%s' "$orphans" | grep -c . || true)

  if [ "$count" -gt 0 ]; then
    total_orphans=$((total_orphans + count))

    if [ "$OUTPUT_JSON" -eq 1 ]; then
      [ $first_branch -eq 0 ] && printf ','
      first_branch=0
      printf '{"branch":"%s","count":%d,"commits":[' "$branch" "$count"
      first_commit=1
      while IFS= read -r line; do
        [ -z "$line" ] && continue
        sha=$(printf '%s' "$line" | awk '{print $1}')
        msg=$(printf '%s' "$line" | cut -d' ' -f2- | sed 's/"/\\"/g')
        [ $first_commit -eq 0 ] && printf ','
        first_commit=0
        printf '{"sha":"%s","subject":"%s"}' "$sha" "$msg"
      done <<< "$orphans"
      printf ']}'
    else
      printf '\n\033[1;33m⚠ %s\033[0m (%d orphan fix commits)\n' "$branch" "$count"
      printf '%s\n' "$orphans" | sed 's/^/    /'
    fi
  fi
done

if [ "$OUTPUT_JSON" -eq 1 ]; then
  printf '],"total":%d}\n' "$total_orphans"
else
  printf '\n──────────────────────────────────────────\n'
  if [ "$total_orphans" -eq 0 ]; then
    printf '\033[1;32m✅ No orphan fix commits. main is up to date.\033[0m\n'
  else
    printf '\033[1;31m🔴 %d orphan fix commits detected across branches.\033[0m\n' \
      "$total_orphans"
    printf '   See docs/BRANCH_WORKFLOW.md for backport procedure.\n'
  fi
fi

[ "$total_orphans" -eq 0 ] && exit 0 || exit 1
