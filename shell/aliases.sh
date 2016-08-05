#!/bin/bash
# Works for zsh and bash
# Configure aliases and functions

# grep
alias grep='grep --color=auto'

# ls
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias l.='ls -d .*'
alias ls='ls --color=auto'

# other
alias dspurge='find . -name .DS_Store -delete'
alias bc='bc -l'

# editing of things
alias vial="\$EDITOR ~/.dotfiles/shell/aliases.sh"

# latexmk
alias latexmk='latexmk -pdf'

# General convenience of things
alias gpg="gpg2"

# Vimlike commandline bindings
alias :q="exit"
alias :e="\$EDITOR"

# Ed
alias ed="ed -p:"

# Make "ag" available everywhere
alias ag="ag || ack"

# Why not!
alias kitten="curl -s https://placekitten.com/\$(shuf -i 100-1000 -n 1)/\
\$(shuf -i 100-1000 -n 1) | imgcat"

if [ -f "/usr/libexec/java_home" ]; then
    # Sets the version to the specified version
    # Kind of actually just a glorified alias to /usr/libexed/java_home
    # use -v <version> to set the version to the specified version
    function jhome () {
        JAVA_HOME="$(/usr/libexec/java_home "$@")"
        export JAVA_HOME
        echo "JAVA_HOME:" "$JAVA_HOME"
        echo "java -version:"
        java -version
    }
fi

# Sets up an eclipse workspace
# First the workspace must exist then run this command with the path
# to the workspace as the argument
# The settings folder of the workspace will be deleted and symlinked to
# The template workspace at ~/.templates/eclipse
function eclset () {
    present_dir="$PWD"
    cd  "$1/.metadata/.plugins/org.eclipse.core.runtime" || exit
    rm -rf .settings
    ln -s ~/.templates/eclipse/.metadata/.plugins/org.eclipse.core.runtime/.settings .settings
    cd "$present_dir" || exit
}

# Swaps the location of two files
function swap () {
    local TMPFILE=tmp.$$
    mv "$1" $TMPFILE
    mv "$2" "$1"
    mv $TMPFILE "$2"
}

# Recursively traverse directory tree for git repositories, run git command
# e.g.
#   gittree status
#   gittree diff
function gittree () {
    if [ $# -lt 1 ]; then
        echo "Usage: gittree <command>"
        return 1
    fi
    local gitdirs
    gitdirs="$(find . -type d -name .git)"
    for gitdir in $gitdirs; do
        # Display repository name in blue
        repo=$(dirname "$gitdir")
        echo -e "\033[34m$repo\033[0m"

        # Run git command in the repositories directory
        cd "$repo" && git "$@"
        ret=$?

        # Return to calling directory (ignore output)
        cd - > /dev/null || exit

        # Abort if cd or git command fails
        if [ $ret -ne 0 ]; then
            return 1
        fi

        echo
    done
}

function up () {
    count="$1"
    while [ "$count" -gt 0 ]; do
        cd ..
        ((count--))
    done
}

function real () {
    cd "$(realpath "$PWD")" || exit
}

if [ -f "$HOME/.aliases.local" ]; then
    source "$HOME/.aliases.local"
fi

# ZSH specific aliases and functions
if [ -n "$ZSH_VERSION" ]; then
    # Goes to a section of the man pages for zsh in vim
    # https://github.com/wellle/dotfiles/blob/master/zshrc
    function zman () {
        PAGER="less -g -s '+/^       $1'" man zshall
    }
fi
