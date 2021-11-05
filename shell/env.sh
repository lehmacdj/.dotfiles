#!/bin/bash

# System name
[ "$(uname)" = "Darwin" ] && export DARWIN=1
[ "$(uname)" = "Linux" ] && export LINUX=1

# Path configuration
cond_path_add () {
    [ -n "$1" ] || (echo "cond_path_add requires 1 argument"; exit 1)
    [ -d "$1" ] && PATH="$1:$PATH"
}

# Private bin
cond_path_add "$HOME/bin"

# Dotfiles bin
cond_path_add "$DOTFILES/bin"

# Local bin
cond_path_add "$HOME/.local/bin"

# Rust
if [ -d "$HOME/.cargo" ]; then
    # Cargo bin
    PATH="$HOME/.cargo/bin:$PATH"
    # PATH="$HOME/.cargo/bin:$PATH"
    # Rust src folder
    # toolchain="$(rustup toolchain list | awk '/\(default\)/{print $1}')"
    # RUST_HOME="$HOME/.rustup/toolchains/$toolchain"
    # PATH="$RUST_HOME/bin:$PATH"
    # export RUST_SRC_PATH="$HOME/.rustup/toolchains/$toolchain/lib/rustlib/src/rust/src"
fi

# Homebrew
if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# OPAM configuration
. /Users/devin/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true

# Haskell/ghcup config
[ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env"

# nvm (node version manager) config
export NVM_DIR="$HOME/.nvm"
[ -f "/usr/local/opt/nvm/nvm.sh" ] && source "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -f "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && source "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# Add fzf to path
if [ -d "$HOME/.fzf" ]; then
    PATH="$PATH:$HOME/.fzf/bin"
    MANPATH="$MANPATH:$HOME/.fzf/man"
fi

# Add python local --user bins to the path
if [ -d "$HOME"/Library/Python ]; then
    for p in "$HOME"/Library/Python/* ; do
        PATH="$p/bin:$PATH"
    done
fi

# Windows (WSL) things
[ -d /mnt/c/Windows ] || export WINDIR=/mnt/c/Windows
cond_path_add "/mnt/c/ProgramData/chocolatey/bin" # chocolatey installations
cond_path_add "/mnt/c/Windows/System32" # cmd.exe
cond_path_add "/mnt/c/Windows/System32/WindowsPowerShell/v1.0" # powershell.exe

# Nix setup
if [ -e /Users/devin/.nix-profile/etc/profile.d/nix.sh ]; then
    . /Users/devin/.nix-profile/etc/profile.d/nix.sh
fi

# Remove inconsistent path entries and export
if [ -f "$DOTFILES/bin/consolidate-path" ]; then
    PATH="$(consolidate-path "$PATH")"
    MANPATH="$(consolidate-path "$MANPATH")"
fi
export PATH
export MANPATH

# setting up editor has to happen after path setting up because otherwise
# nvim isn't necessarily on the path yet

# Editor variables
if nvim --version >/dev/null 2>&1; then
    EDITOR='nvim'
    VISUAL='nvim'
elif vim --version >/dev/null 2>&1; then
    EDITOR='vim'
    VISUAL='vim'
else
    EDITOR='vi'
    VISUAL='vi'
fi
export EDITOR
export VISUAL

# XDG config goes in default location
export XDG_CONFIG_HOME="$HOME/.config"

# Use (n)vim for manpager if it is available
if test "$EDITOR" = 'nvim'; then
    export MANWIDTH=1110
    export MANPAGER="nvim +Man!"
elif test "$EDITOR" = 'vim'; then
    export MANPAGER="vim -M +MANPAGER -"
fi
