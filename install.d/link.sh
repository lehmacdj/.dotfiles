#!/bin/bash

# Links all of the files with the extension .sym to the home directory.

DOTFILES="$HOME/.dotfiles"

echo "Creating symlinks..."

tolink=$(find -H "$DOTFILES" -maxdepth 3 -name '*.sym')

for file in $tolink; do
    target="$HOME/.$(basename $file ".sym")"
    if [ -e $target -o -h $target ]; then
        echo "~${target#$HOME} exists... Skipping."
    else
        echo "Creating symlink for $file"
        ln -s $file $target
    fi
done
