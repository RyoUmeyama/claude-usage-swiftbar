#!/bin/bash

set -e

PLUGIN_DIR="$HOME/Library/Application Support/SwiftBar/Plugins"

echo "=== Claude Usage SwiftBar Plugin Uninstaller ==="
echo ""

# Remove plugin
if [ -f "$PLUGIN_DIR/claude-usage.2m.sh" ]; then
  rm "$PLUGIN_DIR/claude-usage.2m.sh"
  echo "Plugin removed."
else
  echo "Plugin not found (already removed)."
fi

# Remove SwiftBar from login items
osascript -e 'tell application "System Events"
  set loginItems to the name of every login item
  if "SwiftBar" is in loginItems then
    delete login item "SwiftBar"
  end if
end tell' 2>/dev/null
echo "SwiftBar removed from login items."

echo ""
echo "Done! Plugin has been uninstalled."
echo "Note: SwiftBar itself was not removed. To remove it:"
echo "  brew uninstall --cask swiftbar"
