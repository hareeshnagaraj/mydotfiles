#!/usr/bin/env bash
# Self-contained git segment for the tmux status bar (Catppuccin Mocha).
# Emits a fully-styled tmux pill when the pane is inside a git repo, and
# NOTHING when it isn't — so the segment collapses cleanly outside repos.
#
# Symbol reflects working-tree state:
#   ✔ clean    ● dirty (staged/modified/untracked)
# Upstream sync appended when an upstream is set:
#   ⇡N ahead   ⇣N behind   ⇕A/B diverged
#
# Usage: git-status.sh "<pane_current_path>"
#
# Fail-soft: any unexpected error exits 0 with no output so the status bar
# never shows a red shell error from a broken segment.
set +e
set +o pipefail

# --- Catppuccin Mocha palette (flavor is pinned to mocha in ~/.tmux.conf) ---
CRUST="#11111b"   # dark text on colored pill
TEAL="#94e2d5"    # clean repo
PEACH="#fab387"   # dirty repo

# Match status-interval (15s). Skip re-probing when tmux redraws for other reasons.
CACHE_TTL_SEC=15

dir="${1:-$PWD}"
cd "$dir" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

toplevel="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cache_dir="${TMPDIR:-/tmp}/tmux-git-status-cache"
mkdir -p "$cache_dir" 2>/dev/null
cache_key="$(printf '%s' "$toplevel" | tr -c 'A-Za-z0-9._-' '_')"
cache_file="$cache_dir/$cache_key"

if [ -f "$cache_file" ]; then
  now="$(date +%s 2>/dev/null)" || now=0
  mtime="$(stat -f %m "$cache_file" 2>/dev/null)" || mtime=0
  age=$(( now - mtime ))
  if [ "$age" -ge 0 ] && [ "$age" -lt "$CACHE_TTL_SEC" ]; then
    cat "$cache_file" 2>/dev/null
    exit 0
  fi
fi

branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)"
if [ -z "$branch" ]; then
  branch="$(git rev-parse --short HEAD 2>/dev/null)"
  [ -z "$branch" ] && exit 0
  branch=":${branch}"          # detached HEAD → :<sha>
fi

# Same porcelain check as before — proven, no SIGPIPE tricks.
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  symbol="●"; accent="$PEACH"
else
  symbol="✔"; accent="$TEAL"
fi

sync=""
counts="$(git rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null)"
if [ -n "$counts" ]; then
  behind="$(printf '%s' "$counts" | awk '{print $1}')"
  ahead="$(printf '%s' "$counts" | awk '{print $2}')"
  if [ "${ahead:-0}" -gt 0 ] && [ "${behind:-0}" -gt 0 ]; then
    sync=" ⇕${ahead}/${behind}"
  elif [ "${ahead:-0}" -gt 0 ]; then
    sync=" ⇡${ahead}"
  elif [ "${behind:-0}" -gt 0 ]; then
    sync=" ⇣${behind}"
  fi
fi

# Floating rounded pill: left cap + body (crust text on accent) + right cap.
out="$(printf '#[fg=%s,bg=default]#[fg=%s,bg=%s] 󰊢 %s %s%s #[fg=%s,bg=default,nobold]' \
  "$accent" "$CRUST" "$accent" "$branch" "$symbol" "$sync" "$accent")"
printf '%s' "$out" >"$cache_file" 2>/dev/null
printf '%s' "$out"
exit 0
