#!/usr/bin/env bash
# $ means shift so in this file we want to ignore 2016
# shellcheck disable=2016

defaults write com.googlecode.iterm2 NSUserKeyEquivalents '
{
    "New Tab with Current Profile" = "@t";
    "Quit and Keep Windows" = "@q";
    "Select Pane Above" = "@$k";
    "Select Pane Below" = "@$j";
    "Select Pane Left" = "@$h";
    "Select Pane Right" = "@$l";
}
'

defaults write com.tinyspeck.slackmacgap NSUserKeyEquivalents '
{
    Back = "^o";
    Forward = "^i";
}
'
