# prompt
if starship help >/dev/null 2>&1; then
  # this is all fairly slow from profiling, maybe worth caching build-starship
  # or just building our own prompt that doesn't depend on starship #performance
  "$DOTFILES/starship/build-starship.sh"
  export STARSHIP_CONFIG="$DOTFILES/starship/right_prompt.starship.toml"
  eval "$(starship init zsh)"
else
  export PROMPT="%~> "
fi

function put_pwd_in_titles() {
  # Put the string "/full/directory/path" in the title bar:
  set_window_title "$PWD"

  # Put the parentdir/currentdir in the tab
  set_tab_title "$PWD:h:t/$PWD:t"
}
# precmd runs before each prompt is displayed, this is effectively just after
# each command finishes running
precmd_functions+=(put_pwd_in_titles)
