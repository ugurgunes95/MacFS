#!/bin/sh
set -e
cd "$(dirname "$0")"

APP=MacFS.app
BID="${MACFS_BUNDLE_ID:-dev.macfs.agent}"
VER=1.0.1

rm -rf "$APP" MacFS.zip
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -o "$APP/Contents/MacOS/MacFS" main.swift
cp AppIcon.icns "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>MacFS</string>
    <key>CFBundleIdentifier</key><string>$BID</string>
    <key>CFBundleName</key><string>MacFS</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleVersion</key><string>$VER</string>
    <key>CFBundleShortVersionString</key><string>$VER</string>
    <key>LSUIElement</key><true/>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
</dict>
</plist>
EOF

codesign --force --sign - "$APP"
ditto -c -k --keepParent "$APP" MacFS.zip
echo "built $APP and MacFS.zip (v$VER)"
