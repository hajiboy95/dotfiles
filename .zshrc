#!/bin/zsh
# shellcheck shell=bash

### 🛠️ Zsh Configuration

# 1. Automatically remove duplicates from these arrays
# shellcheck disable=SC2034
typeset -U path PATH fpath FPATH

### 🔧 PATH SETUP

# Add local bin directories
export PATH="$HOME/.local/bin:$HOME/flutter/bin:$PATH"

# Add PostgreSQL 17
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

# Add Node.js 20
export PATH="/opt/homebrew/opt/node@20/bin:$PATH"

### 🐳 Docker CLI Completions
fpath=("$HOME/.docker/completions" "${fpath[@]}")

# Initialize completions ONCE for everything (Docker, Git, Zsh, etc.)
autoload -Uz compinit
compinit

### 🐢 Lazy Load NVM (Speed Optimization)
# Only loads NVM when you type 'nvm', 'node', or 'npm'
export NVM_DIR="$HOME/.nvm"
nvm_load() {
  # Unset the placeholder functions so they don't loop
  unset -f nvm node npm

  # Load the real NVM script
  # shellcheck disable=SC1091
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"

  # Load NVM bash_completion (optional, slightly slower)
  # shellcheck disable=SC1091
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

  # Run the command the user actually typed
  "$@"
}

# Create placeholder functions that trigger the loader
nvm() { nvm_load nvm "$@"; }
node() { nvm_load node "$@"; }
npm() { nvm_load npm "$@"; }

### 🧭 Utilities
# 🧭 zoxide (cd replacement)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh --cmd cd)"
fi

# 🔍 fzf (fuzzy finder)
if command -v fzf >/dev/null 2>&1; then
  # shellcheck disable=SC1090
  source <(fzf --zsh)
  bindkey '^Z' fzf-cd-widget
fi

# Direnv Hook (Automatic Venv Switching)
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# 🦇 Use 'bat' instead of 'cat' if available
if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
fi

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons'
fi

_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)
      fzf "$@" --preview 'eza --tree --color=always --level=2 --git --icons {} | head -200'
      ;;
    *)
      fzf "$@" --preview 'bat --color=always --style=numbers --line-range=:500 {}'
      ;;
  esac
}

### 🍺 Homebrew Settings
export HOMEBREW_NO_ENV_HINTS=1

# ==========================================
# 🎨 UI & COLORS (Starship + Ghostty)
# ==========================================

# 1. Force the terminal to announce it supports 256 colors
export TERM="xterm-256color"

# 2. Enable color output for standard macOS commands
export CLICOLOR=1

# 3. Alias 'grep' to always use colors
alias grep='grep --color=auto'

# 4. Load Starship Prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# 5. Syntax Highlighting
# Ask Homebrew exactly where the file is so it never breaks
if command -v brew >/dev/null 2>&1; then
    syntax_path="$(brew --prefix zsh-syntax-highlighting)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

    if [ -f "$syntax_path" ]; then
        # shellcheck disable=SC1090
        source "$syntax_path"
    fi
fi

# ==========================================
# 🖼️ STARTUP EYE CANDY
# ==========================================

function generate_quote() {
    if [[ "$LINES" -lt 60 ]]; then
        if [[ "$LINES" -ge 30 ]]; then
            local small_animals=( alpaca bong bud-frogs bunny cower default elephant elephant-in-snake eyes flaming-sheep head-in hellokitty kitty koala llama luke-koala meow moofasa moose mutilated sheep skeleton small supermilker sus three-eyes tux udder vader vader-koala www )
            local random_cow=${small_animals[$RANDOM % ${#small_animals[@]} + 1]}
            fortune -s | cowsay -f "$random_cow" 2>/dev/null | lolcrab
        elif [[ "$LINES" -ge 20 ]]; then
            local very_small_animals=( bunny default hellokitty mutilated small supermilker three-eyes www )
            local random_cow=${very_small_animals[$RANDOM % ${#very_small_animals[@]} + 1]}
            fortune -s | cowsay -f "$random_cow" 2>/dev/null | lolcrab
        else
            # Not enough room for a cow, just text
            fortune -s | lolcrab
        fi
    else
        fortune | cowsay -r | lolcrab
    fi
}

function print_banner() {
    if [[ "$LINES" -ge "$BANNER_HEIGHT_THRESHOLD" ]]; then
      fastfetch
      echo ""
    fi
    generate_quote
}

# Run on startup
print_banner

# Override clear
alias clear='clear && generate_quote'
