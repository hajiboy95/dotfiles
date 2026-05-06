#!/bin/zsh
# shellcheck disable=SC1071
# .env_power.zsh - Heavy toolchain setup for Zsh
# Sourced by .zshrc for both humans (lazy) and agents (eager).

export NVM_DIR="$HOME/.nvm"

# 🐢 Lazy Load NVM logic
# We define this globally so subshells have access to the function
nvm_load() {
  # Unset the placeholder functions so they don't loop
  unset -f nvm node npm npx 2>/dev/null || true

  # Load the real NVM script
  # shellcheck disable=SC1091
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"

  # Load NVM bash_completion
  # shellcheck disable=SC1091
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

  # Ensure a node version is active so 'node' is on PATH
  if [ -n "$(command -v nvm)" ] && [ "$(nvm current 2>/dev/null)" = "none" ]; then
    nvm use default >/dev/null 2>&1 || true
  fi

  # If arguments were passed, run them
  if [ $# -gt 0 ]; then
    "$@"
  fi
}

# Create placeholder functions that trigger the loader
# These must be defined outside the guard so subshells see them
nvm() { nvm_load nvm "$@"; }
node() { nvm_load node "$@"; }
npm() { nvm_load npm "$@"; }
npx() { nvm_load npx "$@"; }

# 🤖 Agent Eager Loading
# We use a guard to prevent redundant loading in the same shell session,
# but we DO NOT export it, so subshells will re-evaluate and load tools if needed.
if [[ -z "$_ENV_POWER_LOADED" ]]; then
    _ENV_POWER_LOADED=1

    if [[ -n "$ANTIGRAVITY_AGENT" ]]; then
        nvm_load
    fi
fi
