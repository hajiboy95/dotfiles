#!/usr/bin/env bash

set -eu

DOTFILES_DIR="$HOME/dotfiles"

SBAR_LUA_DIR="$HOME/.local/share/sketchybar_lua"
if [ ! -d "$SBAR_LUA_DIR" ]; then
  echo "🎨 Installing SbarLua module..."
  # Clone, compile, install, and clean up in one go
  if (git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && \
      cd /tmp/SbarLua/ && \
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
  (cd "$MENU_HELPER_DIR" && make)

  # Verify the binary was actually created
  if [ -x "$MENU_HELPER_DIR/bin/menus" ]; then
    echo "✅ 'menus' helper compiled successfully."
  else
    echo "❌ Failed to compile 'menus' helper."
    exit 1
  fi
else
  echo "⚠️ Makefile not found in $MENU_HELPER_DIR. Skipping compilation."
fi
# ==============================================================

echo "🔐 Making scripts in ~/.config/sketchybar executable..."
find "$HOME/.config/sketchybar" -type f -name "*.sh" -exec chmod +x {} \;
echo "🔐 Making scripts in ~/.config/aerospace_scripts executable..."
find "$HOME/.config/aerospace_scripts" -type f -name "*.sh" -exec chmod +x {} \;
