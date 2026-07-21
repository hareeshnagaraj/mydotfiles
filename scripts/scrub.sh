#!/usr/bin/env bash
# scrub.sh — redact secrets from a config stream, and hard-scan for leftovers.
#
#   ./scrub.sh redact  < infile   > outfile   # replace known secret shapes with placeholders
#   ./scrub.sh scan     <file...>             # exit 1 if ANY secret shape remains (used as a commit gate)
#
# The redactor is best-effort; the scanner is the real gate. Nothing gets committed
# unless `scan` passes clean. Add new patterns to BOTH functions when you add a new
# secret shape to your dotfiles.
set -euo pipefail

redact() {
  sed -E \
    -e 's#(HCLOUD_TOKEN=)[A-Za-z0-9]+#\1<<YOUR_HCLOUD_TOKEN>>#g' \
    -e "s#(GBRAIN_REMOTE_TOKEN=['\"]?)[A-Za-z0-9_]+#\1<<YOUR_GBRAIN_TOKEN>>#g" \
    -e 's#gbrain_[0-9a-f]{24,}#<<GBRAIN_TOKEN>>#g' \
    -e 's#(([Bb]earer|[Tt]oken)[= :]+)[A-Za-z0-9._-]{20,}#\1<<TOKEN>>#g' \
    -e 's#sk-[A-Za-z0-9_-]{16,}#<<API_KEY>>#g' \
    -e 's#sk-ant-[A-Za-z0-9_-]{16,}#<<ANTHROPIC_KEY>>#g' \
    -e 's#gh[pousr]_[A-Za-z0-9]{16,}#<<GH_TOKEN>>#g' \
    -e 's#xox[baprs]-[A-Za-z0-9-]{10,}#<<SLACK_TOKEN>>#g' \
    -e 's#AKIA[0-9A-Z]{16}#<<AWS_KEY>>#g' \
    -e 's#-----BEGIN [A-Z ]*PRIVATE KEY-----#<<PRIVATE_KEY_REMOVED>>#g' \
    -e 's#(([0-9]{1,3}\.){3}[0-9]{1,3})#<<IP_REDACTED>>#g' \
    -e "s#/Users/$USER#\$HOME#g"
}

# Regexes that must NOT survive into a committed file. IPs and $HOME-safe paths are
# handled by redact; here we gate on high-entropy credentials only.
SCAN_PATTERNS=(
  'HCLOUD_TOKEN=[A-Za-z0-9]{20,}'
  'gbrain_[0-9a-f]{24,}'
  'sk-(ant-)?[A-Za-z0-9_-]{16,}'
  'gh[pousr]_[A-Za-z0-9]{16,}'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
  'AKIA[0-9A-Z]{16}'
  'BEGIN [A-Z ]*PRIVATE KEY'
  '([Bb]earer|[Aa]uthorization)[= :]+[A-Za-z0-9._-]{24,}'
)

scan() {
  local hit=0 f p
  for f in "$@"; do
    [ -f "$f" ] || continue
    for p in "${SCAN_PATTERNS[@]}"; do
      if grep -nEI "$p" "$f" >/dev/null 2>&1; then
        echo "LEAK in $f matching /$p/:" >&2
        grep -nEI "$p" "$f" >&2 || true
        hit=1
      fi
    done
  done
  if [ "$hit" -ne 0 ]; then
    echo "SECRET SCAN FAILED — refusing to proceed." >&2
    return 1
  fi
  echo "secret scan clean: $* "
}

cmd="${1:-}"; shift || true
case "$cmd" in
  redact) redact ;;
  scan)   scan "$@" ;;
  *) echo "usage: scrub.sh {redact|scan} ..." >&2; exit 2 ;;
esac
