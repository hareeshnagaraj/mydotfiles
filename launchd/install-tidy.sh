#!/usr/bin/env bash
# Load a weekly LaunchAgent that runs `dev-tidy --notify`: a macOS notification when
# ~/Development or ~/Downloads has drifted. Read-only — it never purges anything.
set -euo pipefail
LABEL="com.hareesh.dev-tidy"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
TIDY="$HOME/.local/bin/dev-tidy"
[ -x "$TIDY" ] || { echo "missing $TIDY — run make install first" >&2; exit 1; }
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs/mydotfiles"

cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array><string>/bin/bash</string><string>-lc</string><string>"$TIDY" --notify</string></array>
  <key>StartCalendarInterval</key>
  <dict><key>Weekday</key><integer>1</integer><key>Hour</key><integer>9</integer><key>Minute</key><integer>5</integer></dict>
  <key>StandardOutPath</key><string>$HOME/Library/Logs/mydotfiles/dev-tidy.out.log</string>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/mydotfiles/dev-tidy.err.log</string>
  <key>ProcessType</key><string>Background</string>
  <key>LowPriorityIO</key><true/>
</dict></plist>
PLIST

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "loaded $LABEL — Mondays 09:05, notifies only when something has drifted."
