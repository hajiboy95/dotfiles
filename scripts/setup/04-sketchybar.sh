#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"

# Kept in step with the auto-rebuild in .config/sketchybar/sketchybarrc: the
# fork carries the command-stream fixes (FelixKratz/SbarLua#62) and builds
# against Lua 5.5, which upstream's old 437bd20 pin predates. Revert both
# together once #62 lands.
SBARLUA_REPO="https://github.com/hajiboy95/SbarLua.git"
SBARLUA_REF="fix/reentrant-transactions"

SBAR_LUA_DIR="$HOME/.local/share/sketchybar_lua"
if [ ! -d "$SBAR_LUA_DIR" ]; then
  echo "🎨 Installing SbarLua module..."
  # Clone, check out the pinned ref, compile, install, and clean up in one go
  rm -rf /tmp/SbarLua
  if (git clone "$SBARLUA_REPO" /tmp/SbarLua && \
      cd /tmp/SbarLua/ && \
      git checkout "$SBARLUA_REF" && \
      make install && \
      rm -rf /tmp/SbarLua/); then
      echo "✅ SbarLua installed successfully."
  else
      echo "❌ Failed to install SbarLua."
  fi
else
  echo "✔️ SbarLua already installed."
fi

# ==================== COMPILE MENUS HELPER ====================
MENU_HELPER_DIR="$DOTFILES_DIR/.config/sketchybar/helpers/menus"

if [ -f "$MENU_HELPER_DIR/makefile" ]; then
  echo "🔨 Compiling 'menus' helper via makefile..."

  # Run make inside the directory
  (cd "$MENU_HELPER_DIR" && make) || true

  # Verify the binary was actually created. A miss is reported but not fatal, so
  # the remaining setup scripts still run.
  if [ -x "$MENU_HELPER_DIR/bin/menus" ]; then
    echo "✅ 'menus' helper compiled successfully."
  else
    echo "❌ Failed to compile 'menus' helper. Sketchybar menu items will be inert."
  fi
else
  echo "⚠️ Makefile not found in $MENU_HELPER_DIR. Skipping compilation."
fi
# ==============================================================

echo "🔐 Making scripts in ~/.config/sketchybar executable..."
find "$HOME/.config/sketchybar" -type f -name "*.sh" -exec chmod +x {} \;

# ==================== KIWIDESK BINARY ====================
# The spaces widget resolves the binary from KIWIDESK_BIN, then
# ~/.local/bin/kiwidesk, then the Homebrew prefixes. Until the cask ships,
# a dev build has to be linked into ~/.local/bin by hand:
#   ln -sfn /path/to/KiwiDesk/.build/release/KiwiDesk ~/.local/bin/kiwidesk
if [ -x "$HOME/.local/bin/kiwidesk" ] || command -v kiwidesk &>/dev/null; then
  echo "✔️ KiwiDesk binary found."
else
  echo "⚠️ No kiwidesk binary on this machine. The sketchybar spaces widget"
  echo "   will draw empty until one is linked into ~/.local/bin."
fi
# ==============================================================
# ==============================================================
