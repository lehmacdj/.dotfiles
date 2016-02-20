# Editor variables
export EDITOR='vim'
export VISUAL='vim'

# System name variables
if [ $(uname) = "Darwin" ]; then
    export DARWIN=1
fi

# Java
if [ -f "/usr/libexec/java_home" ]; then
    export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
fi

# CDPATH
export CDPATH='~/.a'

export HOMEBREW_CASK_OPTS='--appdir=/Applications'
