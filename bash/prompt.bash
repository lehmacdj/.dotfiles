#!/usr/bin/env bash
if starship help >/dev/null 2>&1; then
  "$DOTFILES/starship/build-starship.sh"
  export STARSHIP_CONFIG="$DOTFILES/starship/starship.toml"
  eval "$(starship init bash)"
  eval "$(starship completions bash)"
else
  export PS1="\w> "
fi
