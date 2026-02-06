#!/usr/bin/env bash

set -eu

DOTFILES_DIR="$HOME/dotfiles"

echo "➡️ Checking for Homebrew..."
if ! command -v brew &>/dev/null; then
  echo "🍺 Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
brew doctor
