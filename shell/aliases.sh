#!/bin/bash
# Works for zsh and bash
# Configure aliases and functions

# use color for grep
alias grep='grep --color=auto'

# ls
if [ -n "$DARWIN" ]; then
    alias ls='gls --color=auto'
else
    alias ls='ls --color=auto'
fi
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alFh'
alias l.='ls -d .*'

# delete .DS_Store files
alias dspurge='find . -name .DS_Store -delete'

# make bc use floats by default
alias bc='bc -l'

# editing of things
function vial {
    "$EDITOR" ~/.dotfiles/shell/aliases.sh
    source "$DOTFILES/shell/aliases.sh"
}

# latexmk default pdf mode
alias latexmk='latexmk -pdfdvi'

# gpg to make it have a easier alias
alias gpg="gpg2"

# Vimlike commandline bindings
alias :q="exit"
alias :e="\$EDITOR"
alias vi="\$EDITOR"
alias vim="\$EDITOR"
alias nvim="\$EDITOR"

# Ed prompt
alias ed="ed -p:"

# Summon a random kitten
alias kitten="curl -s https://placekitten.com/\$(shuf -i 300-1000 -n 1)/\
\$(shuf -i 300-1000 -n 1) | imgcat"

# make java_home accessible
alias java_home='/usr/libexec/java_home'

# work with plist files
alias PlistBuddy='/usr/libexec/PlistBuddy'

# Swaps the location of two files
function swap () {
    local TMPFILE=tmp.$$
    mv "$1" $TMPFILE
    mv "$2" "$1"
    mv $TMPFILE "$2"
}

# move files even if they are the same on case insensitive file systems
function mv_case_insensitive () {
    if [ $# -eq 2 ]; then
        lower1="$(tr '[:lower:]' '[:upper:]' <<< "$1")"
        lower2="$(tr '[:lower:]' '[:upper:]' <<< "$2")"
        if [ "$lower1" = "$lower2" ] && ! [ -f "$1." ]; then
            mv "$1" "$1."
            mv "$1." "$2"
        else
            mv "$@"
        fi
    else
        mv "$@"
    fi
}

alias mv=mv_case_insensitive

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

# go up $1 directories in the hierarchy
function up () {
    count="$1"
    while [ "$count" -gt 0 ]; do
        cd ..
        ((count--))
    done
}

# cd to the realpath of the current path
# Depends on gnu-realpath
function real () {
    cd "$(realpath "$PWD")" || exit
}

# source the local aliases file (the file is "local_aliases.sh")
function alias_local () {
    if [ -f "local_aliases.sh" ]; then
        source "local_aliases.sh"
    else
        echo "no local alias file available for sourcing!"
        exit 1
    fi
}

# create a directory then return a string equal to that directory name
# example usage: `mv file $(dir dir)`
function dir () {
    if test $# -ne 1; then
        echo 'usage: dir <dir-name>'
        return 1
    fi
    mkdir -p "$1"
    echo "$1"
}

alias al=alias_local

# Goes to a section of the man pages for zsh in vim
# https://github.com/wellle/dotfiles/blob/master/zshrc
if [ -n "$ZSH_VERSION" ]; then
    function zman () {
        PAGER="less -g -s '+/^       $1'" man zshall
    }
fi

# launch eclim
if [ -f "/Applications/Eclipse.app/Contents/Eclipse/eclimd" ]; then
    alias eclimd='/Applications/Eclipse.app/Contents/Eclipse/eclimd'
fi

# convert a binary string to a hexadecimal string
if [ -n "$ZSH_VERSION" ]; then
    function bin2hex () {
        typeset -i16 a="2#$1"; echo "${a#16\#}"
    }
fi

alias idris='idris --nobanner'
alias swipl='rlwrap swipl'
