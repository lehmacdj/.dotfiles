function precmd {
  # vcs_info
  # Put the string "hostname::/full/directory/path" in the title bar:
  echo -ne "\e]2;$PWD\a"

  # Put the parentdir/currentdir in the tab
  echo -ne "\e]1;$PWD:h:t/$PWD:t\a"
}

function zshaddhistory {
    emulate -L zsh
    setopt extendedglob
    [[ $1 != ${~HISTORY_IGNORE} ]]
}
