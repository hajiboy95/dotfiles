#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"
NOTEBOOK_CLEANING_DIR="$DOTFILES_DIR/notebook_cleaning"

echo "➡️ Checking for UV Package and Project manager..."
if ! command -v uv &>/dev/null; then
  echo "🌐 Installing UV CLI tool..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  # The installer drops uv in ~/.local/bin, which this shell doesn't know about yet.
  export PATH="$HOME/.local/bin:$PATH"
else
  echo "✔️ uv already installed."
fi

if [ -d "$NOTEBOOK_CLEANING_DIR" ]; then
  echo "📓 Syncing Python dependencies in notebook_cleaning with uv..."
  cd "$NOTEBOOK_CLEANING_DIR"
  if uv sync; then
    echo "✅ uv sync completed in $NOTEBOOK_CLEANING_DIR."
  else
    echo "❌ uv sync failed in $NOTEBOOK_CLEANING_DIR."
  fi
else
  echo "📁 notebook_cleaning directory not found at $NOTEBOOK_CLEANING_DIR. Skipping uv sync."
fi
