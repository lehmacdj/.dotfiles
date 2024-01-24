#!/bin/bash
# shellcheck disable=1003
# Works for zsh and bash
# Configure aliases and functions

# use color for grep
alias grep='grep --color=auto'

# ls
if [ -n "$DARWIN" ] && gls >/dev/null 2>&1; then
    alias ls='gls --color=auto'
else
    'ls' --color=auto >/dev/null 2>&1 && alias ls='ls --color=auto'
fi
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alFh'
alias l.='ls -d .*'

# this is to have a zero exit code so the terminal window closes when I
# accidentally use :q to try to quit from the shell before using exit. I
# decided that it wasn't worth mapping :q to exit because I sometimes quit
# windows I intend to keep open on accident then
alias ":q"='echo "Use '"'"'exit'"'"' to quit"'

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

# Vimlike commandline bindings
# alias :q="exit" # I have found this alias is bad because I close the shell
                  # unexpectedly sometimes when I don't want to
if "$EDITOR" --version >/dev/null 2>&1; then
  alias :e="\$EDITOR"
  alias vi="\$EDITOR"
  alias vim="\$EDITOR"
  alias nvim="\$EDITOR"
fi

# Ed prompt
alias ed="ed -p:"

# Summon a random kitten
alias kitten="curl -s https://placekitten.com/\$(shuf -i 300-1000 -n 1)/\
\$(shuf -i 300-1000 -n 1) | imgcat"

# work with plist files
alias PlistBuddy='/usr/libexec/PlistBuddy'

# Swaps the location of two files
function swap () {
    if [ $# -ne 2 ]; then
        echo "usage: swap <file1> <file2>"
        return 1
    fi
    # $$ is the current PID
    local TMPFILE=tmp.swap.$$
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
            command mv "$1" "$1."
            command mv "$1." "$2"
        else
            command mv "$@"
        fi
    else
        command mv "$@"
    fi
}

alias mv=mv_case_insensitive
alias rn=mv_case_insensitive # rename to match ge's command

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
        # shellcheck disable=1091
        source "local_aliases.sh"
    else
        echo "no local alias file available for sourcing!"
        exit 1
    fi
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

# The intended use case for this function is to find a package root identifying
# file. e.g. `Cargo.toml` or `*.cabal` or something similar.
# This functionality isn't finished being implemented though and I haven't
# missed it so maybe I should just delete this. (2022-05-06)
function find-above () {
    if test $# -ne 1; then
        echo '"Finds a certain filepath in any parent of the current directory"'
        echo 'usage: find-above <path>'
        return 1
    fi
    FILE=$1
    DIR="$PWD"
    while [[ "$DIR" != '/' ]]; do
        if [[ -e "$DIR/$1" ]]; then
            echo "$DIR/$1"
            return 0
        else
            DIR="$(dirname "$DIR")"
        fi
    done
    echo "Couldn't find: $1"
    return 1
}

# extract a song from youtube with optimal quality settings + format
# if this transcodes using ffmpeg, it might be best to not be setting
# the audio-format to m4a
# keeps original file in case it seems like a better to use it instead of the
# converted file
function youtube-m4a () {
    yt-dlp -f bestaudio --audio-quality 0 --extract-audio -k --audio-format m4a "$@"
}

# download the highest resolution album art for a youtube video thumbnail and
# convert it to a square image. Intended for use with songs whose image is square
# to begin with.
function youtube-album-art () {
    if [ $# -ne 1 ]; then
        echo "usage: $0 <youtube url>"
        return 1
    fi
    thumbnail="$(mktemp -t thumbnail).webp"
    curl -s "$(youtube-dl -f best --get-thumbnail "$1")" > "$thumbnail"
    convert "$thumbnail" -gravity center -extent "$(identify -format "%h" "$thumbnail")x" "albumart.jpg"
}

function trash () {
    [ $# -le 0 ] && echo "trash requires at least one argument." && return 1
    command mv "$@" "$HOME/.Trash"
}

# converts a path like /mnt/c/... to C:\...
function windows-path () {
    [ $# -le 0 ] && echo "windows-path requires at least one argument." && return 1
    echo -E "$1" | sed 's|^/mnt/\(.\)|\1:|' | tr '/' '\\'
}

function unix-path () {
    [ $# -le 0 ] && echo "unix-path requires at least one argument." && return 1
    echo -E "$1" | sed 's|^\(.\):|/mnt/\L\1|' | tr '\\' '/'
}

# generate + return a 9 character random sequence of alphanumeric characters
function random-id () {
  LC_ALL=C </dev/urandom tr -dc 'A-Za-z0-9' | head -c 10
}

function date-timestamp () {
    date +"%FT%H:%M-%Z"
}

function hs-replace {
    [ $# -ge 2 ] || {
        echo >&2 "usage: hs-replace <find-pattern> <replace-pattern>"
        return 1
    }
    rg --glob '*.hs' "$1" --files-with-matches \
        | tr '\n' '\0' \
        | xargs -0 sed -i '.sed-backup~' -e "s/$1/$2/g"
    find . -name '*.sed-backup~' -delete;
}

function silently () {
    >/dev/null 2>&1 "$@"
}

# print the cpu temperature every few seconds in the terminal
function cpu-temp() {
    sudo powermetrics --samplers smc | grep -i "CPU die temperature"
}

# edit all files with a git conflict and populate them into the quickfix list
# depends on 'git conflicts' alias defined in the global git config
# requires being in the root of the git repository because of the way git
# conflicts works
function viconflicts () {
    # this is technically broken for filenames containing newlines but that
    # should be pretty rare right?
    git conflicts | tr '\n' '\0' | xargs -0 "$EDITOR" +"vimgrep /<<<<<<</g ##" "$*"
}

function virg () {
    { [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; } && {
        [ $# -eq 0 ] && >&2 echo "error: $0 requires at least one argument"
        >&2 echo "usage: $0 [-u|-uu|--pcre2|--glob <glob>|--multiline] <vim-search-pattern> [<PCRE2-search-pattern>]"
        return 1
    }
    arguments=()
    while true; do
        case "$1" in
            --pcre2)
                shift
                arguments+=("--pcre2")
                ;;
            -u)
                shift
                arguments+=("-u")
                ;;
            -uu)
                shift
                arguments+=("-uu")
                ;;
            --glob)
                shift
                arguments+=("--glob" "$1")
                shift
                ;;
            --multiline)
                shift
                arguments+=("--multiline")
                ;;
            --)
                shift
                break
                ;;
            *)
                break
                ;;
        esac
    done
    [ $# -ge 1 ] || {
        >&2 echo "usage: $0 [--pcre2|--glob|-u] <search-pattern> [<vim-search-pattern>]"
        return 1
    }
    if ! [ $# -ge 2 ]; then
        # the default is to use a vim verymagic syntax regex for ripgrep & vim,
        # but we try to convert some simple things to PCRE automatically
        # if automatic conversion is insufficient the user can specify their own
        # PCRE2 regex

        local converted_word_boundaries
        # no way to do this with just variable substitution
        # shellcheck disable=2001
        converted_word_boundaries="$(echo -n "$1" | sed -E 's/([^\\]|^)[<>]/\1\\b/g')"
        # PCRE doesn't interpret <> specially so we should unescape <>
        converted_word_boundaries="${converted_word_boundaries//\\</<}"
        converted_word_boundaries="${converted_word_boundaries//\\>/>}"

        set -- "$1" "$converted_word_boundaries"
    fi
    # editor is most likely set to something that supports vimgrep
    rg "${arguments[@]}" --files-with-matches --null -- "$2" | xargs -0 "$EDITOR" +"vimgrep /\v$1/ ##"
}

function imgdiff () {
    [ $# -eq 2 ] || {
        >&2 echo "usage: $0 <image1> <image2>"
        return 1
    }
    if ! command -v magick >/dev/null 2>&1; then
        >&2 echo "error: $0 requires imagemagick"
        return 1
    fi

    tmpfile="$(mktemp -t imgdiff).png"
    magick compare "$1" "$2" "$tmpfile"
    open "$tmpfile"
}

# helper function for making stgit easier to use; `stg` is hard to type because
# it's all in one hand and st series which I want to do fairly frequently is
# even more annoying to type
function st () {
    if [ -z "$*" ]; then
        stg series
        git s
    else
        stg "$@"
    fi
}

# Unfortunately this is relatively frequently necessary when Xcode ends up with
# a broken cache and starts producing weird errors
ddd () {
  read -r "REPLY?Are you sure you want to delete all Xcode Derived Data? "
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    rm -rf ~/Library/Developer/Xcode/DerivedData
  fi
}
