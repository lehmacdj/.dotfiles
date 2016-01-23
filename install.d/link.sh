#!/bin/bash
#
# Links all of the files with the extension .sym to the home directory.
# If a file with a .sym extension is in a directory it is linked to the 
# location in the home directory that coresponds to the file in that
# directory.  For example ~/.dotfiles/bin/consolidate-path.sym is 
# symlinked to ~/bin/consolidate-path
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

echo "Creating symlinks..."

tolink=$(find -H "$DOTFILES" -maxdepth 3 -name '*.symdot')

for file in $tolink; do
    target="$HOME/.$(basename $file ".symdot")"
    if [ -e $target -o -h $target ]; then
        echo "~${target#$HOME} exists... Skipping."
    else
        echo "Creating symlink for $file"
        ln -s $file $target
    fi
done

Symlink the bin if it exists.
if [ -e ~/bin ]; then
    echo "~/bin exists... Skipping."
else
    echo "Creating symlink for ~/bin"
    ln -s ~/.dotfiles/bin ~/bin
fi
