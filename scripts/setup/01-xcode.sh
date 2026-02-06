#!/usr/bin/env bash

set -eu

echo "➡️ Checking for Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
  echo "➡️ Installing Command Line Tools..."
  xcode-select --install
  echo "⚠️ Please complete the installation of the Command Line Tools and re-run this script."
  exit 1
else
  echo "✔️ Xcode Command Line Tools already installed."
fi
