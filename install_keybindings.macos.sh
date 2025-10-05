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

# I found this doesn't work very well, and takes a while to start working for
# new apps
# also conflicts with a default keybinding:
# https://support.mozilla.org/en-US/questions/1466675
# System Settings > Keyboard > Keyboard Shortcuts > Keyboard > Show Contextual Menu
# pbs is the service that runs services; this adds a keybinding to kitty quick access to all apps
# defaults write pbs NSServicesStatus \
#     -dict-add "net.kovidgoyal.kitty-quick-access - Quick access to kitty - quickAccessTerminal" \
#     '{
#         "key_equivalent" = "^\n";
#         NSRequiredContext = {};
#     }'
