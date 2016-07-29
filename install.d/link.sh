#!/bin/bash
#
# Links all of the files with the extension .sym* to the home directory.
# Files are linked based on the full suffix of the file (e.g. .symdot files are
# linked with a prepended . and .symdot.osx files do the same but only on osx
# systems
#
# Possible ways to obtain the dotfiles directory without it having to
# be in ~/.dotfiles
# Currently the program assumes dotfiles directory is at ~/.dotfiles
#
# # less portable easier looking
# ${$(realpath $0)%install}
#
# # complicated but portable
# pushd $(dirname $0) > /dev/null
# SCRIPTPATH=$(pwd)
# popd > /dev/null

DOTFILES="$HOME/.dotfiles"

echo -e "\nCreating symlinks..."

# Takes a pattern (e.g. ".symdot" and a function that transforms the basename
# of the file to its destination then links all files ending in the pattern to
# the correct location
function linkfiles {
    local pattern="$1"
    local mapper="$2"
    tolink=$(find -H "$DOTFILES" -maxdepth 5 -name "*$pattern")
    for file in $tolink; do
        local target
        target="$("$mapper" "$(basename "$file" "$pattern")")"
        if [ -e "$target" ] || [ -h "$target" ]; then
            echo "$target exists... Skipping."
        else
            echo "Creating symlink for $file"
            ln -s "$file" "$target"
        fi
    done
}

function symdot_mapper { echo "$HOME/.$1"; }
# Symlink files to be symlinked to every platform
linkfiles ".symdot" "symdot_mapper"
# Symlink OS X specific files
[ -n "$DARWIN" ] && linkfiles ".symdot.osx" "symdot_mapper"

function config_mapper { echo "$HOME/.config/$1"; }
# Symlink files that should go in XDG_CONFIG_HOME
linkfiles ".symconfig" "config_mapper"
