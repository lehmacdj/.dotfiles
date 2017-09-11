#!/bin/bash
#
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

if test "$EDITOR" = 'vim' || test "$EDITOR" = 'nvim'; then
    # Use (n)vim for manpager if it is available
    export MANPAGER="\$EDITOR -c 'set ft=man' -"
fi

# System name
[ "$(uname)" = "Darwin" ] && export DARWIN=1
[ "$(uname)" = "Linux" ] && export LINUX=1

# Path configuration
# Private bin
[ -d "$HOME/bin" ] && PATH="$HOME/bin:$PATH"

# Dotfiles bin
[ -d "$DOTFILES/bin" ] && PATH="$DOTFILES/bin:$PATH"

# Local bin
[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"

# Rust
if [ -d "$HOME/.cargo" ]; then
    # Cargo bin
    export PATH="$HOME/.cargo/bin:$PATH"
    # PATH="$HOME/.cargo/bin:$PATH"
    # Rust src folder
    # toolchain="$(rustup toolchain list | awk '/\(default\)/{print $1}')"
    # RUST_HOME="$HOME/.rustup/toolchains/$toolchain"
    # PATH="$RUST_HOME/bin:$PATH"
    # export RUST_SRC_PATH="$HOME/.rustup/toolchains/$toolchain/lib/rustlib/src/rust/src"
fi

# Homebrew
if which brew >/dev/null 2>&1; then
    BREW_PREFIX="$(brew --prefix)"

    PATH="$BREW_PREFIX/bin:$PATH"
    PATH="$BREW_PREFIX/sbin:$PATH"
    MANPATH="$BREW_PREFIX/share/man:$MANPATH"
fi

# OCaml/OPAM configuration
if [ -f "$HOME/.opam/opam-init/init.sh" ]; then
    source "$HOME/.opam/opam-init/init.sh" > /dev/null 2>&1 || true
    eval "$(opam config env)"
fi

# Add Haskell bin to the path
if [ -d "$HOME/Library/Haskell/" ]; then
    PATH="$PATH:$HOME/Library/Haskell/bin"
    MANPATH="$MANPATH:$HOME/Library/Haskell/share/man"
fi

# Add fzf to path
if [ -d "$HOME/.fzf" ]; then
    PATH="$PATH:$HOME/.fzf/bin"
    MANPATH="$MANPATH:$HOME/.fzf/man"
fi

# Remove inconsistent path entries and export
if [ -f "$DOTFILES/bin/consolidate-path" ]; then
    PATH="$(consolidate-path "$PATH")"
    MANPATH="$(consolidate-path "$MANPATH")"
fi
export PATH
export MANPATH
