#!/bin/bash
# shellcheck disable=1003
# Works for zsh and bash
# Configure aliases and functions

alias grep='grep --color=auto'
alias rg='rg --hyperlink-format=kitty'

declare _ls_executable_name=ls
if [ -n "$DARWIN" ]; then
    _ls_executable_name='gls'
fi
# shellcheck disable=2139
alias ls="$_ls_executable_name --color=auto --hyperlink=auto"

alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alFh'
alias l.='ls -d .*'

alias g='git'

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
    search_string="$1"
    "$EDITOR" ${search_string:++"/$search_string"} ~/.dotfiles/shell/aliases.sh
    source "$DOTFILES/shell/aliases.sh"
}

# latexmk default pdf mode
alias latexmk='latexmk -pdfdvi'

# Vimlike commandline bindings
# alias :q="exit" # I have found this alias is bad because I close the shell
                  # unexpectedly sometimes when I don't want to
if command -v "$EDITOR" >/dev/null 2>&1; then
  alias :e="\$EDITOR"
  alias vi="\$EDITOR"
  alias vim="\$EDITOR"
  alias nvim="\$EDITOR"
fi

# Ed prompt
alias ed="ed -p:"

# Summon a random kitten
alias summon-kitten="curl -s https://placekitten.com/\$(shuf -i 300-1000 -n 1)/\
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

# useful for preserving `cd -` behavior by making the last cd a direct cd
# to a different directory for scripts that `cd` multiple times but want to
# appear as though they are atomic
# NOTE: zsh doesn't seem to respect `export OLDPWD=<something>` which
# necessitates this more complex approach
function setoldpwd () {
    # shellcheck disable=2015
    [ -d "$1" ] || {
        echo "setoldpwd: must pass valid dir"; return 1
    }
    initial_dir="$PWD"
    cd "$1" || return
    cd "$initial_dir" || return
}

# go up to the root of a project directory
function root () {
    root_markers=(.git .hg .svn .jj)
    root_subdir_target="$1"
    initial_oldpwd="$OLDPWD"
    initial_dir="$PWD"
    while [ "$PWD" != "/" ] && [ "$PWD" != "$HOME" ]; do
        for marker in "${root_markers[@]}"; do
            if [ -d "$marker" ] || [ -f "$marker" ]; then
                break 2
            fi
        done
        cd ..
    done
    if [ -n "$root_subdir_target" ] && ! cd "$root_subdir_target"; then
        2>&1 echo "cannot cd to subdirectory '$root_subdir_target' of the root"
        cd "$initial_dir" || return
        setoldpwd "$initial_oldpwd"
    fi
    setoldpwd "$initial_dir"
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

# launch eclim
if [ -f "/Applications/Eclipse.app/Contents/Eclipse/eclimd" ]; then
    alias eclimd='/Applications/Eclipse.app/Contents/Eclipse/eclimd'
fi

alias idris='idris --nobanner'
alias swipl='rlwrap swipl'

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

# converts a path like /mnt/c/... to C:\...
function windows-path () {
  [ $# -le 0 ] && echo "windows-path requires at least one argument." && return 1
  echo -E "$1" | sed 's|^/mnt/\(.\)|\1:|' | tr '/' '\\'
}

function unix-path () {
  [ $# -le 0 ] && echo "unix-path requires at least one argument." && return 1
  echo -E "$1" | sed 's|^\(.\):|/mnt/\L\1|' | tr '\\' '/'
}

# generate + return random sequence of alphanumeric characters
function random-id () {
  character_count="${1:-10}"
  LC_ALL=C </dev/urandom tr -dc 'A-Za-z0-9' | head -c "$character_count"
}

function date-timestamp () {
  date +"%FT%H:%M-%Z"
}

function replace {
  [ $# -eq 1 ] || [ $# -eq 2 ] || {
    echo >&2 "usage: replace [--glob <glob> ...] <find-pattern> [<replace-pattern>]"
    echo >&2 "usage: replace: find/replace all files under the current directory"
    echo >&2 "usage: You can skip the replace pattern to preview what will be replaced."
    return 1
  }
  local globs=()
  while [ "$1" = "--glob" ]; do
    shift
    globs+=("--glob")
    globs+=("$1")
    shift
  done
  local target
  target="$1"
  if [ $# -eq 1 ]; then
    rg "$target" --multiline --pcre2 "${globs[@]}"
  else
    local substitution
    substitution="${2:-}"
    rg "${globs[@]}" --multiline --pcre2 "$target" --files-with-matches --null \
        | xargs -0n1 perl -p0i -e "s/$target/$substitution/smg"
  fi
}

function silently () {
  >/dev/null 2>&1 "$@"
}

# print the cpu temperature every few seconds in the terminal
function cpu-temp() {
  sudo powermetrics --samplers smc | grep -i "CPU die temperature"
}

# for some reason nvim fails to resume in specifically in zsh if the files
# are piped into xargs
# using <<< works, but we need to use a while loop to read the files to
# properly handle filenames that contain spaces
function xargs_newlines_vim () {
    local -a args=()
    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        args+=("$line")
    done
    "$EDITOR" "$@" "${args[@]}"
}

# edit all files with a git conflict and populate them into the quickfix list
# depends on 'git conflicts' alias defined in the global git config
# requires being in the root of the git repository because of the way git
# conflicts works
function viconflicts () {
    # for some reason nvim fails to resume in specifically in zsh if the files
    # are piped into xargs
    # using <<< works, but appends an extra newline to the list of files so we
    # have the remove the last argument from the list
    xargs_newlines_vim +"vimgrep /<<<<<<</g ##" <<<"$(git conflicts)"
}

# edit all files with a git conflict and populate them into the quickfix list
# depends on 'git conflicts' alias defined in the global git config
# requires being in the root of the git repository because of the way git
# conflicts works
function vihunks () {
    xargs_newlines_vim +":GitGutterQuickFix" +":cc 1" <<<"$(git diff --name-only)"
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
    files="$(echo -n "$(rg "${arguments[@]}" --files-with-matches -- "$2")")"
    if [ -z "$files" ]; then
        echo "no matches of regex found"
        return 1
    fi
    # for some reason nvim fails to resume in specifically in zsh if the files
    # are piped into xargs
    xargs_newlines_vim +"vimgrep /\v$1/ ##" <<<"$files"
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

# Move and simlink at the original location
# if multiple files are moved to a single directory link all of them
mvln() {
    if [ "$#" -lt 2 ]; then
        echo "mvln: missing file operand"
        echo "Usage: mvln source... destination"
        return 1
    fi

    local sources=()
    while [ $# -gt 1 ]; do
        sources+=("$1")
        shift
    done
    local dest="$1"

    if [ -d "$dest" ]; then
        for src in "${sources[@]}"; do
            mv "$src" "$dest"
            ln -s "$dest/$(basename "$src")" "$src"
        done
    else
        if [[ ${#sources[@]} -gt 1 ]]; then
            echo "mvln: target '$dest' is not a directory"
            return 1
        else
            src="${sources[0]}"
            mv "$src" "$dest"
            ln -s "$dest" "$src"
        fi
    fi
}

set_window_title() {
  [ -z "$1" ] && { echo "Usage: set_window_title <title>"; return 1; }
  echo -ne "\e]2;$1\a"
}

set_tab_title() {
  [ -z "$1" ] && { echo "Usage: set_tab_title <title>"; return 1; }
  echo -ne "\e]1;$1\a"
}

set_term_titles() {
  [ -z "$1" ] && { echo "Usage: set_term_titles <title>"; return 1; }
  set_window_title "$1"
  set_tab_title "$1"
}

# start editing notes (with the right CWD) from anywhere
vii() {
  if ! [ -d "$HOME/wiki" ]; then
    echo "error: $HOME/wiki does not exist"
    return 1
  fi
  # for god knows what reason --cmd and -c have different behaviors in nvim:
  # - --cmd runs before any plugins are loaded
  # - -c runs after plugins are loaded
  # we need to run before plugins are loaded so that LSPs are loaded in the
  # correct working directory
  "$EDITOR" --cmd "cd $HOME/wiki" "$HOME/wiki/index.md" "$@"
}

alias isodate='date -u +"%Y-%m-%d"'
alias isots='date -u +"%Y-%m-%dT%H:%M:%SZ"'
