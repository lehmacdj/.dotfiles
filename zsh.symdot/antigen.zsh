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
source ~/.zsh/fix.zsh

# Apply settings
antigen apply
