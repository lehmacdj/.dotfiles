#!/bin/bash

# Install homebrew and brew everything in Brewfile

echo -e "\nInstalling xcode commandline tools..."
xcode-select --install


# Install homebrew if nescessary
brew help >/dev/null 2>&1 || \
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

echo -e "\nBrewing formulas..."

# Use brew-bundle to install brewfiles in a good order
brew tap Homebrew/bundle 2>/dev/null
brew bundle --file="~/.dotfiles/Brewfile"
