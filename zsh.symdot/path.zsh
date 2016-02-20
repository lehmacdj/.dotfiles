# Configure the path

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

if [ -e "~/bin/consolidate-path" ]; then
    PATH="$(consolidate-path "$PATH")"
fi

export PATH
