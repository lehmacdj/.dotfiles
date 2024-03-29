export ANTIGEN_COMPDUMP="$HOME/.dotfiles/zsh/.zcompdump"

if [ -f "$DOTFILES/antigen/antigen.zsh" ]; then
  source "$DOTFILES/antigen/antigen.zsh"
else
  >&2 echo "antigen.zsh not found; maybe the git submodule hasn't been cloned?"
  # initialize completion anyways, this is the most important thing that antigen
  # always does, this will get some functionality anyways
  autoload -U +X compinit && compinit -d "$ANTIGEN_COMPDUMP"
  return # skip sourcing the rest of the script because it won't work anyways
fi

# Bundles
antigen bundle gitfast
antigen bundle brew
antigen bundle brew-cask
antigen bundle man
antigen bundle vagrant

# Syntax
antigen bundle zsh-users/zsh-syntax-highlighting

# Apply settings
antigen apply
