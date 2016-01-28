#!/bin/bash
#
# Install eclim.  Depends on the installation of eclipse.
# Right now only works on os x.

java \
    -Dvim.files="$HOME/.vim" \
    -Declipse.home="/Applications/Eclipse.app/Contents/Eclipse" \
    -jar eclim_2.5.0.jar install
