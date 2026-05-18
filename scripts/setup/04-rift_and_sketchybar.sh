#!/usr/bin/env bash

set -eu

DOTFILES_DIR="$HOME/dotfiles"

SBAR_LUA_DIR="$HOME/.local/share/sketchybar_lua"
if [ ! -d "$SBAR_LUA_DIR" ]; then
  echo "🎨 Installing SbarLua module..."
  # Clone, checkout Lua 5.4 compatible commit (437bd20), compile, install, and clean up in one go
  if (git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && \
      cd /tmp/SbarLua/ && \
      git checkout 437bd20 && \
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

# ==================== COMPILE RIFT IPC CLIENT ====================
RIFT_CLIENT_DIR="$DOTFILES_DIR/.config/sketchybar/rift-client"
mkdir -p "$RIFT_CLIENT_DIR/bin"

if [ ! -f "$RIFT_CLIENT_DIR/bin/rift.so" ]; then
  echo "🔨 Dynamically cloning and compiling 'rift' IPC client library..."

  # Clone to temp directory
  rm -rf /tmp/rift.lua
  git clone https://github.com/acsandmann/rift.lua.git /tmp/rift.lua

  # Determine architecture
  if [ "$(uname -m)" = "arm64" ]; then
    ARCH_FLAG="arm64"
  else
    ARCH_FLAG="x86_64"
  fi

  # Get lua@5.4 prefix
  if command -v brew &> /dev/null; then
    LUA_PREFIX=$(brew --prefix lua@5.4)
  elif [ -d "/opt/homebrew/opt/lua@5.4" ]; then
    LUA_PREFIX="/opt/homebrew/opt/lua@5.4"
  else
    LUA_PREFIX="/usr/local/opt/lua@5.4"
  fi

  # Compile using clang
  if clang -std=c99 -O3 -g -shared -fPIC -arch "$ARCH_FLAG" /tmp/rift.lua/src/*.c \
     -I"$LUA_PREFIX/include/lua5.4" \
     -undefined dynamic_lookup \
     -framework CoreFoundation \
     -o "$RIFT_CLIENT_DIR/bin/rift.so"; then
    echo "✅ 'rift' IPC library compiled successfully."
  else
    echo "❌ Failed to compile 'rift' IPC library."
    rm -rf /tmp/rift.lua
    exit 1
  fi

  # Clean up temp clone
  rm -rf /tmp/rift.lua
else
  echo "✔️ 'rift' IPC library already compiled."
fi
# ==============================================================

echo "🔐 Making scripts in ~/.config/sketchybar executable..."
find "$HOME/.config/sketchybar" -type f -name "*.sh" -exec chmod +x {} \;

# ==================== RIFT SERVICE STARTUP ====================
if command -v rift &> /dev/null; then
  echo "🌀 Configuring Rift Service..."
  # Only run install if the launchd agent plist does not exist
  if [ ! -f "$HOME/Library/LaunchAgents/git.acsandmann.rift.plist" ]; then
    rift service install
  fi
  # Start/ensure the service is running
  rift service start
  echo "✅ Rift service installed and started."
else
  echo "⚠️ 'rift' command not found. Please install rift first."
fi
# ==============================================================
