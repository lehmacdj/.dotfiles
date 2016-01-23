#!/bin/bash

# Install homebrew and brew everything in Brewfile

echo "Installing xcode commandline tools..."
xcode-select --install

echo

echo "Brewing formulas..."

# Install homebrew if nescessary
brew help >/dev/null 2>&1 || \
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Use brew-bundle to install brewfiles in a good order
brew tap Homebrew/bundle
brew bundle --file="~/.dotfiles/Brewfile"
