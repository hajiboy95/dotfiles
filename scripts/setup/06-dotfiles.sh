#!/usr/bin/env bash

set -eu

DOTFILES_DIR="$HOME/dotfiles"

echo "⚓ Installing pre-commit hooks..."
if command -v pre-commit &>/dev/null; then
  pre-commit install
  echo "✅ pre-commit hooks installed."
else
  echo "⚠️ pre-commit not found. Skipping hook installation."
fi

if [ -d "$DOTFILES_DIR" ]; then
  echo "📂 Stowing dotfiles..."
  cd "$DOTFILES_DIR"
  stow .
else
  echo "❌ Dotfiles directory $DOTFILES_DIR does not exist. Skipping stow."
fi
