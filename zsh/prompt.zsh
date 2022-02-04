if starship help >/dev/null 2>&1; then
  "$DOTFILES/starship/build-starship.sh"
  export STARSHIP_CONFIG="$DOTFILES/starship/right_prompt.starship.toml"
  eval "$(starship init zsh)"
else
  export PROMPT="%~> "
fi
