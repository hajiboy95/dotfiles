#!/bin/zsh
# shellcheck shell=bash
# .env_power.zsh - Heavy toolchain setup for Zsh
# Sourced by .zshrc for both humans (lazy) and agents (eager).

if [[ -z "$_ENV_POWER_LOADED" ]]; then
    export _ENV_POWER_LOADED=1

    export NVM_DIR="$HOME/.nvm"

    # 🐢 Lazy Load NVM (Original logic from .zshrc)
    nvm_load() {
      # Unset the placeholder functions so they don't loop
      unset -f nvm node npm npx

      # Load the real NVM script
      # shellcheck disable=SC1091
      [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"

      # Load NVM bash_completion
      # shellcheck disable=SC1091
      [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

      # If arguments were passed, run them
      if [ $# -gt 0 ]; then
        "$@"
      fi
    }

    # Create placeholder functions that trigger the loader
    nvm() { nvm_load nvm "$@"; }
    node() { nvm_load node "$@"; }
    npm() { nvm_load npm "$@"; }
    npx() { nvm_load npx "$@"; }

    # 🤖 Agent Eager Loading
    # If running as an agent, we want tools available IMMEDIATELY
    if [[ -n "$ANTIGRAVITY_AGENT" ]]; then
        nvm_load
    fi
fi
