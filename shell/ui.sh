
set_window_title() {
  [ -z "$1" ] && { echo "Usage: set_window_title <title>"; return 1; }
  echo -ne "\e]2;$1\a"
}

set_tab_title() {
  [ -z "$1" ] && { echo "Usage: set_tab_title <title>"; return 1; }
  echo -ne "\e]1;$1\a"
}

set_term_titles() {
  [ -z "$1" ] && { echo "Usage: set_term_titles <title>"; return 1; }
  set_window_title "$1"
  set_tab_title "$1"
}
