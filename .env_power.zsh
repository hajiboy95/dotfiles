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

  # Select a node version so 'node' is on PATH.
  #
  # This used to run only when `nvm current` was exactly "none". That fires for a
  # shell with no node at all, but not for one that *inherited* a stale node from
  # its launcher: GUI apps and IDE agents start from a login environment captured
  # at boot, `typeset -U path` in .zshenv preserves that PATH entry, and the
  # non-interactive shells they spawn never reach the interactive `load-nvmrc`
  # hook. So the stale version was accepted and a project's .nvmrc never won —
  # e.g. Claude Code running KiwiCV (.nvmrc = 24) on an inherited v20.11.1, where
  # vite/rolldown died on `node:util` not exporting `styleText` (needs >= 20.12).
  #
  # Honour .nvmrc first, then the default alias, regardless of what is already
  # on PATH.
  if [ -n "$(command -v nvm)" ]; then
    if [ -f .nvmrc ] && [ -r .nvmrc ]; then
      nvm use >/dev/null 2>&1 || nvm use default >/dev/null 2>&1 || true
    else
      nvm use default >/dev/null 2>&1 || true
    fi
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
