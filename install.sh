#!/bin/sh
set -e
cd "$(dirname "$0")"

PLIST="$HOME/Library/LaunchAgents/local.macfs.plist"

./build.sh

launchctl unload "$PLIST" 2>/dev/null || true
pkill -x macfs 2>/dev/null || true   # stop pre-app-binary agent if present
pkill -x MacFS 2>/dev/null || true

rm -rf /Applications/MacFS.app
cp -R MacFS.app /Applications/
rm -f "$HOME/.local/bin/macfs"        # superseded by the app bundle

mkdir -p "$HOME/Library/Application Support/MacFS"
[ -f "$HOME/Library/Application Support/MacFS/skip.txt" ] || echo "com.apple.finder" > "$HOME/Library/Application Support/MacFS/skip.txt"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>local.macfs</string>
    <key>ProgramArguments</key>
    <array><string>/Applications/MacFS.app/Contents/MacOS/MacFS</string></array>
    <key>RunAtLoad</key><true/>
</dict>
</plist>
EOF
launchctl load "$PLIST"

echo "installed and running."
echo "grant Accessibility: System Settings -> Privacy & Security -> Accessibility -> MacFS"
echo "logs: log stream --predicate 'subsystem == \"local.macfs\"'"
