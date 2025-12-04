# Custom async zsh prompt
# Replaces starship with native zsh implementation

#
# === Configuration ===
#

typeset -g _PROMPT_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-prompt"
typeset -g _PROMPT_ASYNC_FILE="$_PROMPT_CACHE_DIR/async-$$"
typeset -g _prompt_jj_status=""
typeset -g _prompt_last_exit=0
typeset -g _prompt_async_pid=""

# Ensure cache directory exists
[[ -d "$_PROMPT_CACHE_DIR" ]] || mkdir -p "$_PROMPT_CACHE_DIR"

#
# === Signal Handler for Async Updates ===
#

TRAPUSR1() {
  # Read async result if available
  if [[ -f "$_PROMPT_ASYNC_FILE" ]]; then
    _prompt_jj_status="$(<$_PROMPT_ASYNC_FILE)"
    rm -f "$_PROMPT_ASYNC_FILE"
  fi
  # Reset prompt if zle is active
  zle && zle reset-prompt
}

# Widget to refresh prompt - can be called via zle
_prompt_refresh_widget() {
  if [[ -f "$_PROMPT_ASYNC_FILE" ]]; then
    _prompt_jj_status="$(<$_PROMPT_ASYNC_FILE)"
    rm -f "$_PROMPT_ASYNC_FILE"
  fi
  zle reset-prompt
}
zle -N _prompt_refresh_widget

#
# === Async Worker for jj Status ===
#

_prompt_start_async() {
  # Kill any existing background worker
  if [[ -n "$_prompt_async_pid" ]]; then
    kill "$_prompt_async_pid" 2>/dev/null
  fi

  # Clear previous jj status
  _prompt_jj_status=""

  # Capture variables before subshell (subshell inherits but can't use typeset -g)
  local ppid=$$
  local async_file="$_PROMPT_ASYNC_FILE"

  # Start background worker as inline subshell (disowned to suppress job messages)
  {
    local result=""

    # Check if we're in a jj repo
    if jj root --ignore-working-copy >/dev/null 2>&1; then
      # Check for uncommitted changes in working copy
      if jj status --ignore-working-copy 2>/dev/null | grep -q '^Working copy changes'; then
        result+="+"
      fi

      # Check for unpushed bookmarks (local bookmarks ahead of tracked remotes)
      # Lines without '@' are local-only or ahead of remote
      local unpushed
      unpushed=$(jj bookmark list --tracked 2>/dev/null | grep -v '^ *@' | grep -v '^$' | head -1)
      if [[ -n "$unpushed" ]]; then
        # Verify it's actually ahead (has a line without @origin match)
        if jj bookmark list --tracked 2>/dev/null | awk '
          /^[^ ]/ { name=$1; local_rev=$2 }
          /^ *@/ { if ($2 != local_rev) { found=1; exit } }
          END { exit !found }
        ' 2>/dev/null; then
          result+="*"
        fi
      fi
    fi

    # Write result and signal parent (try multiple times for reliability)
    echo -n "$result" > "$async_file"
    kill -USR1 "$ppid" 2>/dev/null
    sleep 0.05
    kill -USR1 "$ppid" 2>/dev/null
  } &!
  _prompt_async_pid=$!
}

#
# === Left Prompt Components ===
#

_prompt_jobs() {
  (( ${#jobstates} > 0 )) && print -n '⚙️  '
}

_prompt_status() {
  (( _prompt_last_exit != 0 )) && print -n "%F{red}${_prompt_last_exit}%f "
}

_prompt_char() {
  if (( _prompt_last_exit == 0 )); then
    print -n '%F{green}❯%f '
  else
    print -n '%F{red}❯%f '
  fi
}

#
# === Right Prompt Components ===
#

_prompt_nest() {
  (( SHLVL > 1 )) && print -n '🪺 '
}

_prompt_jj() {
  # Also check for async result in case signal was missed
  if [[ -f "$_PROMPT_ASYNC_FILE" ]]; then
    _prompt_jj_status="$(<$_PROMPT_ASYNC_FILE)"
    rm -f "$_PROMPT_ASYNC_FILE"
  fi
  [[ -n "$_prompt_jj_status" ]] && print -n "%F{yellow}${_prompt_jj_status}%f "
}

_prompt_dir() {
  # Use shared format-path script
  local formatted
  formatted=$("$DOTFILES/bin/format-path" "$PWD")

  # Check if it contains | marker (meaning it's a VCS path)
  if [[ "$formatted" == *"|"* ]]; then
    # Split on | marker: before is path prefix (~/), after is repo+subpath
    local path_prefix="${formatted%%|*}"
    local repo_part="${formatted#*|}"

    # Check if repo_part contains / (has subpath)
    if [[ "$repo_part" == *"/"* ]]; then
      local repo_name="${repo_part%%/*}"
      local subpath="${repo_part#*/}"
      # Path prefix blue, repo name pink, slash and subpath blue
      print -n "%B%F{blue}${path_prefix}%f%F{magenta}${repo_name}%f%F{blue}/${subpath}%f%b "
    else
      # At repo root, no subpath
      print -n "%B%F{blue}${path_prefix}%f%F{magenta}${repo_part}%f%b "
    fi
  else
    # No VCS, just blue
    print -n "%B%F{blue}${formatted}%f%b "
  fi
}

_prompt_memory() {
  # Only show when memory usage > 90%
  local page_size total_mem vmstat
  page_size=$(sysctl -n hw.pagesize 2>/dev/null) || return
  total_mem=$(sysctl -n hw.memsize 2>/dev/null) || return
  vmstat=$(vm_stat 2>/dev/null) || return

  local free inactive spec
  free=$(echo "$vmstat" | awk '/Pages free:/ {gsub(/\./,"",$3); print $3}')
  inactive=$(echo "$vmstat" | awk '/Pages inactive:/ {gsub(/\./,"",$3); print $3}')
  spec=$(echo "$vmstat" | awk '/Pages speculative:/ {gsub(/\./,"",$3); print $3}')

  local available used_pct
  available=$(( (free + inactive + spec) * page_size ))
  used_pct=$(( (total_mem - available) * 100 / total_mem ))

  (( used_pct > 90 )) && print -n "%F{magenta}${used_pct}%%%f "
}

_prompt_battery() {
  local batt_info pct

  batt_info=$(pmset -g batt 2>/dev/null) || return
  [[ -z "$batt_info" ]] && return

  # Extract percentage
  pct=$(echo "$batt_info" | grep -oE '[0-9]+%' | head -1 | tr -d '%')
  [[ -z "$pct" ]] && return

  # Only show when battery is critically low (<10%)
  if (( pct < 10 )); then
    print -n "%F{red}🔋${pct}%%%f "
  fi
}

_prompt_user() {
  # Show username when root or SSH
  if [[ "$USER" == "root" ]] || [[ -n "$SSH_CONNECTION" ]]; then
    print -n '%F{yellow}%n%f'
  fi
}

_prompt_host() {
  # Show @hostname when SSH
  if [[ -n "$SSH_CONNECTION" ]]; then
    print -n '%F{yellow}@%m%f '
  elif [[ "$USER" == "root" ]]; then
    print -n ' '
  fi
}

_prompt_time() {
  print -n '%F{yellow}%T%f'
}

#
# === Precmd Hook ===
#

_prompt_precmd() {
  # MUST be first - capture exit status before anything else runs
  _prompt_last_exit=$?

  # Trigger async jj status check
  _prompt_start_async
}

#
# === Setup ===
#

# Add our precmd to the front (must run first to capture exit status)
precmd_functions=(_prompt_precmd "${(@)precmd_functions}")

# Set prompts (prompt_subst must be enabled for function calls to work)
PROMPT='$(_prompt_jobs)$(_prompt_status)$(_prompt_char)'
RPROMPT='$(_prompt_nest)$(_prompt_jj)$(_prompt_dir)$(_prompt_memory)$(_prompt_battery)$(_prompt_user)$(_prompt_host)$(_prompt_time)'

#
# === Cleanup ===
#

_prompt_cleanup() {
  rm -f "$_PROMPT_ASYNC_FILE"
  [[ -n "$_prompt_async_pid" ]] && kill "$_prompt_async_pid" 2>/dev/null
  # Clean up old cache files from previous shells
  find "$_PROMPT_CACHE_DIR" -name 'async-*' -mmin +60 -delete 2>/dev/null
}

# Register cleanup on shell exit
zshexit_functions+=(_prompt_cleanup)
