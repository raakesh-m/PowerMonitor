#!/bin/bash
# Builds PowerMonitor in release mode and packages it as a standalone .app bundle.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP="PowerMonitor.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$(swift build -c release --show-bin-path)/PowerMonitor" "$APP/Contents/MacOS/PowerMonitor"
cp Info.plist "$APP/Contents/Info.plist"

echo "Built $APP"
echo "Run it with: open $APP"
echo "Or install it: cp -r $APP /Applications/"
