export ANTIGEN_COMPDUMPFILE=~/.zsh/.zcompdump

source /usr/local/share/antigen.zsh

# Bundles
antigen bundle git
antigen bundle command-not-found
antigen bundle brew
antigen bundle brew-cask
antigen bundle man

# Syntax
antigen bundle zsh-users/zsh-syntax-highlighting

# Theme
antigen theme agnoster
source ~/.zsh/fix-theme.zsh

# Apply settings
antigen apply
