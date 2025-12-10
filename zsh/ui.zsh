# prompt
if command -v starship >/dev/null 2>&1; then
  ss_dir="$DOTFILES/starship"
  [[ "$ss_dir/template.starship.toml" -nt "$ss_dir/right_prompt.starship.toml" ]] \
    || [[ "$ss_dir/build-starship.sh" -nt "$ss_dir/right_prompt.starship.toml" ]] \
    && "$ss_dir/build-starship.sh"
  export STARSHIP_CONFIG="$ss_dir/right_prompt.starship.toml"
  source <(starship init zsh)
else
  export PS1="%~> "
fi
# source "$DOTFILES/zsh/prompt.zsh" # this is still a work in progress

function put_pwd_in_titles() {
  # Put the string "/full/directory/path" in the title bar:
  set_window_title "$PWD"

  # Put the parentdir/currentdir in the tab
  set_tab_title "$PWD:h:t/$PWD:t"
}
# precmd runs before each prompt is displayed, this is effectively just after
# each command finishes running
precmd_functions+=(put_pwd_in_titles)

# configure the style of the completion prompts
# - reference: https://thevaluable.dev/zsh-completion-guide-examples/
# - this MUST happen before compinit is called, otherwise it is ignored

# Enable completion caching, use rehash to clear
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path ~/.zsh/cache/$HOST

# Fallback to built in ls colors
zstyle ':completion:*' list-colors ''

# Make the list prompt friendly
zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more, or the character to insert%s'

# Make the selection prompt friendly when there are a lot of choices
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'

# Add simple colors to kill
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

# list of completers to use
zstyle ':completion:*::::' completer _expand _complete _ignored _approximate _correct

zstyle ':completion:*' menu select=1 _complete _ignored _approximate

# match uppercase from lowercase
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# offer indexes before parameters in subscripts
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# formatting and messages
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
zstyle ':completion:*' group-name ''

# ignore completion functions (until the _ignored completer)
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:scp:*' tag-order files users 'hosts:-host hosts:-domain:domain hosts:-ipaddr"IP\ Address *'
zstyle ':completion:*:scp:*' group-order files all-files users hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' tag-order users 'hosts:-host hosts:-domain:domain hosts:-ipaddr"IP\ Address *'
zstyle ':completion:*:ssh:*' group-order hosts-domain hosts-host users hosts-ipaddr
zstyle '*' single-ignored show
