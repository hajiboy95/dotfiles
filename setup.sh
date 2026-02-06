#!/usr/bin/env bash

set -eu

# Change directory to dotfiles folder
DOTFILES_DIR="$HOME/dotfiles"
cd "$DOTFILES_DIR"

echo "🔧 Starting main setup..."

# Run all modular setup scripts in order
for script in scripts/setup/[0-9]*.sh; do
  if [ -x "$script" ]; then
    echo "🏃 Running $script..."
    ./"$script"
  else
    echo "🏃 Running $script via bash..."
    bash "$script"
  fi
done

echo "✅ Main setup complete! 🎉"
