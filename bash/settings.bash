#!/bin/bash

# Store more history + append don't overwrite
shopt -s histappend
HISTFILESIZE=1000000
HISTSIZE=100000

# Ignore commands that don't need to be remembered
HISTCONTROL=ignoreboth
HISTIGNORE='ls:ll:bg:fg:history'

# Use one line per command and record time
shopt -s cmdhist
HISTTIMEFORMAT='%F %T '
