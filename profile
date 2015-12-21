# Contains config details for any shell environment

#if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# Set up various shell environment variables

# set the default java version
export JAVA_HOME=`/usr/libexec/java_home -v 1.8`

# Setup the PATH 
if [ -d "$HOME/bin" ] ; then
    # add the user bin
    PATH="$HOME/bin:$PATH"
fi
if [ -d "/usr/local/bin" ]; then
    # put the local bin before the normal bin
    PATH="/usr/local/bin:$PATH"
fi
if [ -d "/usr/local/opt/coreutils/libexec/gnubin" ]; then
    # add the GNU bin to the path (to use gnu coreutils before other stuffs)
    PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
    if [ -d "/usr/local/opt/coreutils/libexec/gnuman" ]; then
        # Set up the path to include the gnu man pages instead of the BSD man pages
        export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
    fi
fi
export PATH

# Add some brew-cask configuration
# Harmless if brew-cask is not installed
export HOMEBREW_CASK_OPTS='--appdir=/Applications'

# # set up dir colors
# not in use because I don't like this color scheme
# if [ -f "$HOME/.dir_colors" ]; then
#     eval $( dircolors -b $HOME/.dir_colors )
# fi
