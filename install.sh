#!/bin/bash
# Installs the dotfiles in this directory by linking them to the files they
# correspond to in the home directory.  The original files remain in this
# directory and can updates can be pulled from the github repository directly.
#
# WARNING: Deletes the existing configuration files that go by the same name as
# the ones contained in this package.

cd "$(dirname "$0")"

# Check for the existence of the files this would overwrite
if [ -f ~/.profile ]; then
    profile=".profile, "
fi
if [ -f ~/.vimrc ]; then
    vimrc=".vimrc, "
fi
if [ -f ~/.bashrc ]; then
    bashrc=".bashrc, "
fi
if [ -f ~/.aliases ]; then
    aliases=".aliases, "
fi
if [ -d ~/.vim ]; then
    vim=".vim"
fi

# Get user confirmation that deleting these files is okay
echo "The following files in your home directory will be deleted:
${profile?}${bashrc?}${aliases?}${vimrc?}${vim?}
Is that okay? [Y/n]"
while [ ! -n "$result" ]; do
    read input
    if [ "$input" == "Y" ]; then
        result="yes"
    elif [ "$input" == "n" ]; then
        result="no"
    else
        echo "Please enter Y or n"
    fi
done

if [ "$result" == "yes" ]; then
    rm ~/.profile
    ln -s profile ~/.profile
    rm ~/.vimrc
    ln -s vimrc ~/.vimrc
    rm ~/.bashrc
    ln -s bashrc ~/.bashrc
    rm ~/.aliases
    ln -s aliases ~/.aliases
    rm -rf ~/.vim
    ln -s vim ~/.vim
else
    echo "Aborted!"
fi
