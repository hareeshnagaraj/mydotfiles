#!/usr/bin/env sh
# _delegate.sh — run a repository's own hook, if it has one.
#
# WHY THIS EXISTS: `core.hooksPath` REPLACES .git/hooks, it does not chain.
# Setting it globally would silently disable every repo-local hook on this
# machine — including this repo's own pre-commit secret-scan gate, and any
# project hook that enforces a commit convention. Every global hook delegates
# through here first so repo-local behavior is preserved exactly.
#
# Called as: _delegate.sh <hook-name> [hook args...]
# Returns:   the repo hook's exit code, or 0 if the repo has no such hook.

_hook_name="$1"
[ -n "$_hook_name" ] || { echo "_delegate.sh: missing hook name" >&2; exit 2; }
shift

# Recursion guard. If a repo hook itself invokes git in a way that re-enters
# this path, stop rather than looping.
_guard="_AI_ATTR_DELEGATED_${_hook_name}"
_guard=$(printf '%s' "$_guard" | tr -c 'A-Za-z0-9_' '_')
eval "_seen=\${$_guard:-}"
[ -n "$_seen" ] && exit 0
export "$_guard=1"

# --git-common-dir so linked worktrees resolve to the main .git, which is where
# hooks actually live. Plain --git-dir points at .git/worktrees/<name>.
_common=$(git rev-parse --git-common-dir 2>/dev/null) || exit 0
[ -n "$_common" ] || exit 0
case "$_common" in /*) ;; *) _common="$(pwd)/$_common" ;; esac

_repo_hook="$_common/hooks/$_hook_name"
[ -e "$_repo_hook" ] || exit 0

# Guard against pointing at ourselves (repo hooksPath == global hooksPath).
_self_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
_hook_dir=$(CDPATH= cd -- "$(dirname -- "$_repo_hook")" && pwd 2>/dev/null) || exit 0
[ "$_self_dir" = "$_hook_dir" ] && exit 0

if [ -x "$_repo_hook" ]; then
    "$_repo_hook" "$@"
else
    # Present but not executable. Stock git would skip it; skipping SILENTLY is
    # worse than stock git because the author believes it ran. Run it via sh and
    # say so.
    echo "hook: $_hook_name exists but is not executable; running via sh" >&2
    sh "$_repo_hook" "$@"
fi
exit $?
