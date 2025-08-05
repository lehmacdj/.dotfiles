#!/usr/bin/env bash
if starship help >/dev/null 2>&1; then
  "$DOTFILES/starship/build-starship.sh"
  export STARSHIP_CONFIG="$DOTFILES/starship/starship.toml"
  eval "$(starship init bash)"
  eval "$(starship completions bash)"
else
  export PS1="\w> "
fi

function put_pwd_in_titles() {
  # Put the string "/full/directory/path" in the title bar:
  set_window_title "$PWD"

  # Put the parentdir/currentdir in the tab
  set_tab_title "$(echo -n "$PWD" | sed 's|.*/\([^/]*/[^/]\)|\1|')"
}

# PROMPT_COMMAND is run just before displaying the prompt, making this
# effectively just after very command finishes running
if [[ -z "$PROMPT_COMMAND" ]]; then
  PROMPT_COMMAND="put_pwd_in_titles"
else
  PROMPT_COMMAND="put_pwd_in_titles; $PROMPT_COMMAND"
fi
