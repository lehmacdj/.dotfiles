# Editor variables
export EDITOR='vim'
export VISUAL='vim'

# System name
[ $(uname) = "Darwin" ] && export DARWIN=1
[ $(uname) = "Linux" ] && export LINUX=1

# Path configuration
# Private bin
[ -d "$HOME/bin" ] && PATH="$HOME/bin:$PATH"

# Dotfiles bin
[ -d "$DOTFILES/bin" ] && PATH="$DOTFILES/bin:$PATH"

# Homebrew
if [ $(which brew) ]; then
    BREW_PREFIX=$(brew --prefix)

    PATH="$BREW_PREFIX/bin:$PATH"

    # Deal with coreutils if installed
    [ -d "$BREW_PREFIX/opt/coreutils/libexec/gnubin" ] &&
        PATH="$BREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"
    [ -d "$BREW_PREFIX/opt/coreutils/libexec/gnuman" ] &&
        MANPATH="$BREW_PREFIX/opt/coreutils/libexec/gnuman:$MANPATH"
fi

if [ "$LINUX" ] && [ -d "$HOME/brew" ]; then
    export PATH="$HOME/brew/bin:$PATH"
    export CPATH="$HOME/brew/include:$CPATH"
    export LD_LIBRARY_PATH="$HOME/brew/lib:$LD_LIBRARY_PATH"
fi

[ -f "$HOME/bin/consolidate-path" ] && PATH="$(consolidate-path "$PATH")"

export PATH

# OCaml/OPAM configuration
if [ -f "$HOME/.opam/opam-init/init.sh" ]; then
    source "$HOME/.opam/opam-init/init.sh" > /dev/null 2>&1 || true
    eval $(opam config env)
fi
