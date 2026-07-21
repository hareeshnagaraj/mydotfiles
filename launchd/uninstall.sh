#!/usr/bin/env bash
set -euo pipefail
LABEL="com.hareesh.mydotfiles.sync"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
launchctl unload "$PLIST" 2>/dev/null || true
rm -f "$PLIST"
echo "unloaded + removed $LABEL"
