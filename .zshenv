#!/bin/zsh
# shellcheck disable=SC1071
# .zshenv - Universal Zsh Environment Variables
# This file is sourced for all zsh instances (interactive, non-interactive, login).
# Use it for PATH and global environment variables only.

# 4. Agent Toolchains (Eager load for Antigravity)
if [[ -n "$ANTIGRAVITY_AGENT" && -f "$HOME/.env_power.zsh" ]]; then
    source "$HOME/.env_power.zsh"
fi

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

# Antigravity IDE bin (separate install from the one above)
export PATH="$HOME/.antigravity-ide/antigravity-ide/bin:$PATH"

# Ensure PATH remains unique
# shellcheck disable=SC2034
typeset -U path PATH

# Rust toolchain. Guarded: .zshenv runs for every zsh, including non-interactive
# ones, so an unguarded source aborts the file on a machine without rustup.
# .cargo/env already prepends ~/.cargo/bin.
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# 5. Node version, for shells the interactive hooks never reach.
#
# .zshrc's load-nvmrc hook and .env_power.zsh's lazy nvm_load both cover
# interactive shells only. A non-interactive zsh — a coding agent's tool shell, a
# subprocess of an app launched from Finder or an IDE — reads this file and
# nothing else, so it kept whatever node sat on the PATH captured at login. That
# is how KiwiCV (.nvmrc = 24) got built under an inherited v20.11.1, where
# vite/rolldown dies on `node:util` not exporting `styleText` (needs >= 20.12).
#
# Pure PATH arithmetic on purpose: sourcing nvm.sh here would run on every single
# zsh, which is the cost the lazy loader exists to avoid.
_pin_node_from_nvmrc() {
  # NVM_BIN is only set by a real `nvm use`, so its presence means an ancestor
  # shell chose deliberately. Respect that; only correct an inherited PATH.
  [[ -n $NVM_BIN ]] && return

  local nvm_root="${NVM_DIR:-$HOME/.nvm}/versions/node"
  [[ -d $nvm_root ]] || return

  # Nearest .nvmrc walking up from $PWD, else the `default` alias.
  local dir=$PWD want=''
  while [[ -n $dir ]]; do
    [[ -r $dir/.nvmrc ]] && { want=$(<"$dir/.nvmrc"); break; }
    dir=${dir%/*}
  done
  [[ -z $want && -r ${NVM_DIR:-$HOME/.nvm}/alias/default ]] &&
    want=$(<"${NVM_DIR:-$HOME/.nvm}/alias/default")
  want=${${want//[[:space:]]/}#v}
  [[ -n $want ]] || return

  # Highest installed version matching the request: `24` -> v24.18.0. The `n`
  # glob qualifier sorts numerically, so v24.18.0 beats v24.9.0 (lexical would
  # pick the wrong one).
  local -a matches=( ${nvm_root}/v${want}*(Nn/) )
  (( $#matches )) || return
  local bin=${matches[-1]}/bin
  [[ -x $bin/node ]] || return

  # Drop any other nvm node bin so the pinned one cannot be shadowed.
  local -a keep=() p
  for p in $path; do
    [[ $p == ${nvm_root}/*/bin ]] || keep+=( $p )
  done
  path=( $bin $keep )
}
_pin_node_from_nvmrc
unfunction _pin_node_from_nvmrc
