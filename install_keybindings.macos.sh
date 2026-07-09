#!/usr/bin/env bash
# $ means shift so in this file we want to ignore 2016
# shellcheck disable=2016

defaults write com.tinyspeck.slackmacgap NSUserKeyEquivalents '
{
    Back = "^o";
    Forward = "^i";
}
'

defaults write com.apple.iphonesimulator NSUserKeyEquivalents '
{
    "Trigger Screenshot" = "@$s";
}
'

# strangely there isn't a default keybinding
# command control l is unbound by default and matches the default commands for
# loop (@l) / A-B loop (@$l)
defaults write org.videolan.vlc NSUserKeyEquivalents '
{
    "Repeat One" = "@^l";
}
'
