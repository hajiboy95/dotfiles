#!/usr/bin/env bash

set -euo pipefail

# Inform the user that setup is starting
echo "🔧 Applying macOS Mission Control and Spaces preferences..."

# Enable grouping of windows by application in Mission Control
echo "➡️  Enabling grouping of windows by application in Mission Control..."
defaults write com.apple.dock expose-group-apps -bool true

# Enable Spaces to span across multiple displays
echo "➡️  Enabling Spaces to span across multiple displays..."
defaults write com.apple.spaces spans-displays -bool true

# Restart the Dock to apply changes for expose-group-apps
echo "🔄 Restarting Dock to apply changes..."
# killall exits non-zero when the process isn't running, which set -e would treat
# as a setup failure.
killall Dock || true
killall SystemUIServer || true

echo "ℹ️  Please log out and log back in for the Spaces setting to fully take effect."
