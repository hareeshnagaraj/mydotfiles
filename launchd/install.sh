#!/usr/bin/env bash
# Load a weekly LaunchAgent that runs `make sync` (scrub + stage). It NEVER commits
# or pushes — it just keeps the repo's scrubbed copy fresh so you commit when you like.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABEL="com.hareesh.mydotfiles.sync"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs/mydotfiles"

cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string><string>-lc</string>
    <string>cd "$REPO" && ./scripts/sync.sh</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict><key>Weekday</key><integer>0</integer><key>Hour</key><integer>10</integer><key>Minute</key><integer>0</integer></dict>
  <key>StandardOutPath</key><string>$HOME/Library/Logs/mydotfiles/sync.out.log</string>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/mydotfiles/sync.err.log</string>
</dict></plist>
PLIST

launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"
echo "loaded $LABEL — runs \`sync.sh\` Sundays 10:00. Logs: ~/Library/Logs/mydotfiles/"
echo "It stages scrubbed changes only; commit + push stay manual."
