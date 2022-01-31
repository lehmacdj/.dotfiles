if starship help >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  export PROMPT="%~> "
fi
