alias -g @silent='>/dev/null 2>&1'
alias -g @bg='@silent & disown'

# Goes to a section of the man pages for zsh in vim
function zman () {
  MANPAGER="$MANPAGER +'/^\\s*$1" man zshall
}

# convert a binary string to a hexadecimal string
function bin2hex () {
  typeset -i16 a="2#$1"; echo "${a#16\#}"
}

mkdir_zmv() {
  _zmv_mkdir_helper() {
      local src="$1"
      local dest="$2"
      mkdir -p "$(dirname "$dest")"
      mv "$src" "$dest"
  }

  # -P specifies a program/function to use for moving without passing --
  zmv -P _zmv_mkdir_helper "$@"
}
