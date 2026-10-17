#!/usr/bin/env bash
# One check for dev-tidy: a clean repo passes, everything else is reported, --purge purges.
set -euo pipefail
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
TIDY="$(cd "$(dirname "$0")/.." && pwd)/dotfiles/bin/dev-tidy"
g() { git -C "$1" -c user.name=t -c user.email=t@t "${@:2}" >/dev/null; }
mkdir -p "$T/bare" "$T/dev/clean" "$T/dev/dirty" "$T/dev/notrepo" "$T/dev/_scratch/old" "$T/dev/_scratch/new"
git init -q --bare "$T/bare"
for r in clean dirty; do g "$T/dev/$r" init -q; g "$T/dev/$r" commit -q --allow-empty -m x
  g "$T/dev/$r" remote add origin "$T/bare"; g "$T/dev/$r" push -q origin HEAD:refs/heads/$r; done
touch "$T/dev/dirty/f"
touch -t 202001010000 "$T/dev/_scratch/old"
out="$(DEV_ROOT="$T/dev" DEV_TIDY_DOWNLOADS_GB=100000 "$TIDY" || true)"
grep -q "dirty=1 .*$T/dev/dirty" <<<"$out"
grep -q "not a repo .*$T/dev/notrepo" <<<"$out"
grep -q "scratch >30 days .*old" <<<"$out"
if grep -qE "/clean$|_scratch/new" <<<"$out"; then echo "FAIL: clean things reported"; exit 1; fi
DEV_ROOT="$T/dev" DEV_TIDY_DOWNLOADS_GB=100000 "$TIDY" --purge >/dev/null || true
[ ! -e "$T/dev/_scratch/old" ] || { echo "FAIL: old scratch not purged"; exit 1; }
[ -e "$T/dev/_scratch/new" ] || { echo "FAIL: new scratch purged"; exit 1; }
echo "dev-tidy ok"
