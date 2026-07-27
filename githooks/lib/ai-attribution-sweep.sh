#!/usr/bin/env sh
# ai-attribution-sweep.sh — recurring drift detector.
#
# A one-shot check at install time cannot see a regression that only appears as
# a slowly rising count over weeks. This is the instrument that can. Read-only.
#
#   ai-attribution-sweep.sh [repo ...]
#   ai-attribution-sweep.sh --update-baseline
#
# With no arguments it reads one repo path per line from `sweep-repos` next to
# this hooks directory. Blank lines and `#` comments are ignored. That file is
# deliberately untracked, so private repo names never reach a public dotfiles
# repository.
#
# Exit 0 = no growth since baseline. Exit 1 = the count grew.

set -u
_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$_dir/ai-attribution.sh"
_baseline="$_dir/../sweep-baseline"
_repolist="$_dir/../sweep-repos"

_update=0
[ "${1:-}" = "--update-baseline" ] && { _update=1; shift; }

if [ $# -gt 0 ]; then
    _repos=$(printf '%s\n' "$@")
elif [ -f "$_repolist" ]; then
    _repos=$(sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$_repolist" | grep -v '^$')
else
    echo "ai-attribution-sweep: no repos given, and no repo list at $_repolist" >&2
    echo "  create it with one repo path per line, or pass paths as arguments." >&2
    exit 2
fi

_tmp=$(mktemp -d) || exit 2
trap 'rm -rf "$_tmp"' EXIT

printf '%-34s %8s %8s %8s\n' "REPO" "FLAGGED" "BASE" "DELTA"
printf '%s\n' "----------------------------------------------------------------"

printf '%s\n' "$_repos" | while IFS= read -r repo; do
    [ -n "$repo" ] || continue
    repo=$(eval echo "$repo")          # allow ~ and $HOME in the list
    [ -d "$repo/.git" ] || { printf '%-34s %8s\n' "$(basename "$repo")" "no-repo"; continue; }
    name=$(basename "$repo")

    # Two stages: ONE git call streams every message and a loose prefilter emits
    # candidate SHAs; the precise scan then runs only on those. Keeps a
    # multi-thousand-commit repo to a few seconds while the exact pattern still
    # decides every result.
    count=0
    git -C "$repo" log --all --format="%x01%H%n%B" 2>/dev/null \
      | awk -v RS='\001' 'NR>1 {
            low = tolower($0)
            if (low ~ /co-authored-by|generated with|assisted by|authored with|written by/ || index($0, "\360\237\244\226") > 0) {
                split($0, a, "\n"); print a[1]
            }
        }' > "$_tmp/cand" 2>/dev/null

    while IFS= read -r sha; do
        [ -n "$sha" ] || continue
        git -C "$repo" log -1 --format=%B "$sha" 2>/dev/null > "$_tmp/m"
        ai_attribution_scan "$_tmp/m" >/dev/null 2>&1 || count=$((count + 1))
    done < "$_tmp/cand"

    base=""
    [ -f "$_baseline" ] && base=$(grep "^$name " "$_baseline" 2>/dev/null | awk '{print $2}')
    if [ -z "$base" ]; then
        printf '%-34s %8d %8s %8s\n' "$name" "$count" "-" "new"
    else
        d=$((count - base))
        flag=""
        [ "$d" -gt 0 ] && { flag=" <-- GREW"; echo grew >> "$_tmp/grew"; }
        printf '%-34s %8d %8d %+8d%s\n' "$name" "$count" "$base" "$d" "$flag"
    fi
    echo "$name $count" >> "$_tmp/new-baseline"
done

_grew=0
[ -f "$_tmp/grew" ] && _grew=1

if [ "$_update" = "1" ] && [ -f "$_tmp/new-baseline" ]; then
    cp "$_tmp/new-baseline" "$_baseline"
    echo ""
    echo "baseline updated -> $_baseline"
fi

echo ""
if [ "$_grew" = "1" ]; then
    echo "RESULT: attribution count GREW since baseline. Investigate before it compounds."
    exit 1
fi
echo "RESULT: no growth since baseline."
exit 0
