#!/bin/bash

set -e

PLUGIN_DIR="$HOME/Library/Application Support/SwiftBar/Plugins"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Claude Usage SwiftBar Plugin Installer ==="
echo ""

# Check if SwiftBar is installed
if [ ! -d "/Applications/SwiftBar.app" ]; then
  echo "SwiftBar is not installed."
  echo "Installing via Homebrew..."
  if ! command -v brew &>/dev/null; then
    echo "Error: Homebrew is not installed. Please install it first:"
    echo "  https://brew.sh"
    exit 1
  fi
  brew install --cask swiftbar
  echo "SwiftBar installed."
else
  echo "SwiftBar is already installed."
fi

# Check if Claude Code credentials exist
if ! security find-generic-password -s "Claude Code-credentials" -w &>/dev/null; then
  echo ""
  echo "Warning: Claude Code credentials not found in Keychain."
  echo "Please log in to Claude Code first:"
  echo "  claude /login"
  echo ""
  echo "The plugin will be installed, but won't work until you log in."
fi

# Create plugin directory
mkdir -p "$PLUGIN_DIR"

# Copy plugin
cp "$SCRIPT_DIR/claude-usage.2m.sh" "$PLUGIN_DIR/claude-usage.2m.sh"
chmod +x "$PLUGIN_DIR/claude-usage.2m.sh"
echo "Plugin installed to: $PLUGIN_DIR/claude-usage.2m.sh"

# Set SwiftBar plugin directory
defaults write com.ameba.SwiftBar PluginDirectory "$PLUGIN_DIR"
echo "SwiftBar plugin directory configured."

# Add SwiftBar to login items (auto-start on boot)
osascript -e 'tell application "System Events"
  set loginItems to the name of every login item
  if "SwiftBar" is not in loginItems then
    make login item at end with properties {path:"/Applications/SwiftBar.app", hidden:false}
  end if
end tell' 2>/dev/null
echo "SwiftBar added to login items (auto-start on boot)."

# Start SwiftBar
if pgrep -q SwiftBar; then
  echo "SwiftBar is already running. Refreshing..."
  killall SwiftBar
  sleep 1
fi
open -a SwiftBar
echo ""
echo "Done! Claude usage should now appear in your menu bar."
echo "  - Updates every 2 minutes"
  echo "  - Click the icon for details"
