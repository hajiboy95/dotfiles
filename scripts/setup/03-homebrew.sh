#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"

echo "➡️ Checking for Homebrew..."
if ! command -v brew &>/dev/null; then
  echo "🍺 Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # A fresh install isn't on PATH until the shellenv runs, and brew bundle is next.
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "❌ Homebrew install finished but no brew binary was found. Aborting."
    exit 1
  fi
else
  echo "✔️ Homebrew already installed."
fi

echo "📦 Installing packages from Brewfile..."
if brew bundle install --file="$DOTFILES_DIR/Brewfile"; then
  echo "✅ Brew bundle install completed successfully."
else
  echo "❌ Brew bundle install encountered errors. Check the output above or in the log."
fi

echo "🩺 Running 'brew doctor' for diagnostics..."
# Diagnostics only: brew doctor exits non-zero on harmless warnings, and under
# set -e that would abort the remaining setup scripts.
brew doctor || true
