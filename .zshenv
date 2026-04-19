#!/bin/zsh
# shellcheck shell=bash
# .zshenv - Universal Zsh Environment Variables
# This file is sourced for all zsh instances (interactive, non-interactive, login).
# Use it for PATH and global environment variables only.

# 1. Initialize Homebrew (Apple Silicon path)
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 2. Intel / Docker Binaries (Standard macOS paths)
export PATH="/usr/local/bin:$PATH"

# 3. Specific Tool Path Overrides (highest priority first)

# PostgreSQL 17
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

# Flutter
export PATH="$HOME/flutter/bin:$PATH"

# Local bin
export PATH="$HOME/.local/bin:$PATH"

# Antigravity bin
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# Ensure PATH remains unique
# shellcheck disable=SC2034
typeset -U path PATH
