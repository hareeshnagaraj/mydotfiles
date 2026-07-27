#!/usr/bin/env bash
# Load a weekly LaunchAgent that runs the AI-attribution drift sweep. Read-only:
# it never edits history, it only reports whether the count grew.
#
# A one-shot check at install time cannot see a regression that only shows up as
# a slowly rising count over weeks. This is the instrument that can.
set -euo pipefail

LABEL="com.hareesh.ai-attribution-sweep"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
SWEEP="${XDG_CONFIG_HOME:-$HOME/.config}/git/hooks/lib/ai-attribution-sweep.sh"

if [ ! -x "$SWEEP" ]; then
  echo "missing $SWEEP — run ./githooks/install.sh first" >&2
  exit 1
fi

mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs/mydotfiles"

cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string><string>-lc</string>
    <string>"$SWEEP"</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict><key>Weekday</key><integer>1</integer><key>Hour</key><integer>9</integer><key>Minute</key><integer>0</integer></dict>
  <key>StandardOutPath</key><string>$HOME/Library/Logs/mydotfiles/attribution-sweep.out.log</string>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/mydotfiles/attribution-sweep.err.log</string>
  <key>ProcessType</key><string>Background</string>
  <key>LowPriorityIO</key><true/>
</dict></plist>
PLIST

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "loaded $LABEL — runs Mondays 09:00. Logs: ~/Library/Logs/mydotfiles/"
echo "Repos scanned come from \${XDG_CONFIG_HOME:-~/.config}/git/hooks/sweep-repos"
