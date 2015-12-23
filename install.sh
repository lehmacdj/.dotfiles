#!/bin/bash
# Installs the dotfiles in this directory by linking them to the files they
# correspond to in the home directory.  The original files remain in this
# directory and can updates can be pulled from the github repository directly.
#
# WARNING: Deletes the existing configuration files that go by the same name as
# the ones contained in this package.

# Check for the existence of the files this would overwrite
if [ -e ~/.profile ]; then
    profile=".profile  "
fi
if [ -e ~/.vimrc ]; then
    vimrc=".vimrc  "
fi
if [ -e ~/.bashrc ]; then
    bashrc=".bashrc  "
fi
if [ -e ~/.aliases ]; then
    aliases=".aliases  "
fi
if [ -e ~/.vim/ftplugin ]; then
    ftplugin=".vim/ftplugin  "
fi

# Get user confirmation that deleting these files is okay
echo "The following files in your home directory will be deleted:
${profile}${bashrc}${aliases}${vimrc}${ftplugin}
In addition you should make sure that this git repository is located
In a directory with the name .dotfiles in your home directory."
while [ ! -n "$result" ]; do
    read -p "Do you want to continue? [Y/n]" input
    if [ "$input" == "Y" ]; then
        result="yes"
    elif [ "$input" == "n" ]; then
        result="no"
    else
        echo "Please enter Y or n"
    fi
done

if [ "$result" == "yes" ]; then
    echo "Moving old files..."
    mv ~/.profile ~/.profile.installerbackup
    mv ~/.vimrc ~/.vimrc.installerbackup
    mv ~/.bashrc ~/.bashrc.installerbackup
    mv ~/.aliases ~/.aliases.installerbackup
    mv ~/.vim/ftplugin ~/.vim/ftplugin.installerbackup
    echo "Linking files..."
    ln -s ~/.dotfiles/ftplugin ~/.vim/ftplugin
    ln -s ~/.dotfiles/profile ~/.profile
    ln -s ~/.dotfiles/vimrc ~/.vimrc
    ln -s ~/.dotfiles/aliases ~/.aliases
    ln -s ~/.dotfiles/bashrc ~/.bashrc
    git clone "https://github.com/VundleVim/Vundle.vim"
    vim +PluginInstall +qall
    echo "Finished! Backups of previous config files were moved to a file with the same"
    echo "name followed by .installerbackup"
else
    echo "Aborted!"
fi
