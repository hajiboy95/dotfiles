#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"

echo "⚓ Installing pre-commit hooks..."
if command -v pre-commit &>/dev/null; then
  pre-commit install
  echo "✅ pre-commit hooks installed."
else
  echo "⚠️ pre-commit not found. Skipping hook installation."
fi

if ! command -v stow &>/dev/null; then
  echo "⚠️ stow not found. Skipping dotfile linking."
elif [ -d "$DOTFILES_DIR" ]; then
  echo "📂 Stowing dotfiles..."
  cd "$DOTFILES_DIR"
  # --restow so re-runs prune links that left the tree instead of erroring.
  stow --restow .
else
  echo "❌ Dotfiles directory $DOTFILES_DIR does not exist. Skipping stow."
fi
