#!/usr/bin/env bash
# We use nonconstant sources intentionally in this file
# shellcheck disable=1090
# Some source files might not exist if their respective tools aren't installed
# shellcheck disable=1091

# System name
[ "$(uname)" = "Darwin" ] && export DARWIN=1
[ "$(uname)" = "Linux" ] && export LINUX=1

if [ -n "$ZSH_VERSION" ]; then
    shell_string="zsh"
elif [ -n "$BASH_VERSION" ]; then
    shell_string="bash"
else
    shell_string="unknown"
fi

export DOTFILES_CACHE="$HOME/.cache/dotfiles"
mkdir -p "$DOTFILES_CACHE"

# Path configuration
cond_path_add () {
    [ -n "$1" ] || (echo "cond_path_add requires 1 argument"; exit 1)
    [ -d "$1" ] && PATH="$1:$PATH"
}

# Homebrew
if [ -f /opt/homebrew/bin/brew ]; then
    # shellcheck disable=1090
    source <(/opt/homebrew/bin/brew shellenv "$shell_string")
fi

# Private bin
cond_path_add "$HOME/bin"

# Dotfiles bin
cond_path_add "$DOTFILES/bin"

# Local bin
cond_path_add "$HOME/.local/bin"

# Git aliases bin
cond_path_add "$DOTFILES/git.symconfig/bin"

# Rust
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

cond_path_add "$HOME/go/bin"

# OPAM configuration
source "/Users/devin/.opam/opam-init/init.$shell_string" >/dev/null 2>&1 || true

# Haskell
cond_path_add "$HOME/.ghcup/bin"
cond_path_add "$HOME/.cabal/bin"
cond_path_add "$HOME/.stack/bin"

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

# dotnet
cond_path_add "$HOME/.dotnet/tools"

# Nix setup
if [ -e /Users/devin/.nix-profile/etc/profile.d/nix.sh ]; then
    source /Users/devin/.nix-profile/etc/profile.d/nix.sh
fi

# setup rbenv
# add executables on rbenv path to the bin
cond_path_add "$HOME/.rbenv/bin"
# shellcheck disable=1090
if command -v rbenv >/dev/null 2>&1; then
    source <(rbenv init - --no-rehash "$shell_string")
fi

# claude code
cond_path_add "$HOME/.claude/local"

# PROFILE_ZSH=1 shows that consolidate path is fairly slow, maybe we can just
# reorganize to avoid adding dups; maybe a file with paths we want in env + a
# single script that iterates through them and then adds them #performance
PATH="$(consolidate-path "$PATH")"
MANPATH="$(consolidate-path "$MANPATH")"
export PATH
export MANPATH

# setting up editor has to happen after path setting up because otherwise
# nvim isn't necessarily on the path yet

# Editor variables
if command -v nvim >/dev/null 2>&1; then
    EDITOR='nvim'
    VISUAL='nvim'
elif command -v vim >/dev/null 2>&1; then
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
    export MANWIDTH=1000
    export MANPAGER="nvim +Man!"
fi

# fpath is a path for files containing function definitions; this includes
# completion functions for zsh, and it must be set before compinit is called
# (most likely by antigen).
cond_fpath_add () {
    [ -n "$1" ] || { echo "cond_fpath_add requires 1 argument"; exit 1; }
    [ -d "$1" ] && FPATH="$1:$FPATH"
}

cond_fpath_add "$HOME/.local/share/zsh-completions"
cond_fpath_add /usr/local/share/zsh-completions
cond_fpath_add "$HOMEBREW_PREFIX/share/zsh-completions"
cond_fpath_add "$HOME/src/beets/extra" # beets zsh completion script lives here
FPATH="$(consolidate-path "$FPATH")"
export FPATH

# Add completions to fpath for zsh
# openspec adds completions here, maybe useful to add completions for other
# things here too
if [ -n "$ZSH_VERSION" ]; then
    cond_fpath_add "$HOME/.zsh/completions"
fi
