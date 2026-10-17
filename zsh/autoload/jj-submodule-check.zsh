#!/bin/zsh -f
# jj-submodule-check: warn when a repo's git submodules aren't checked out
# at the commits the repo pins. jj never moves a submodule (nor does git
# without submodule.recurse), so after switching commits a submodule can
# silently stay at another commit.
#
# This one file serves three callers:
# - interactive zsh sources it and checks before each prompt;
# - run as a program (~/.dotfiles/zsh/autoload/jj-submodule-check.zsh
#   [dir]; it isn't on PATH) it checks the repo around dir on demand;
# - `jj-submodule-check.zsh --hook` is a PreToolUse hook for Claude Code
#   and Codex: it passes the warnings to the agent and never blocks a call.
#
# Why zsh only: the check runs before every prompt and every agent command,
# so it has to be nearly free when nothing changed. zsh's builtin zstat
# tells whether any checkout moved without starting a process (about 0.2 ms
# per prompt, and about 8 ms per hook call, mostly zsh's startup); git and
# jj run only after something moved. bash has no such builtin, so bash
# shells get no prompt warning: run this file as a program there.
#
# In a jj repo the pin is the one in the working-copy commit (@); in a
# plain git repo it is the one in HEAD.

zmodload -F zsh/stat b:zstat
zmodload -F zsh/files b:zf_mv

typeset -g _jjsm_key= _jjsm_out= _jjsm_out_root= _jjsm_gm=
typeset -ga _jjsm_paths _jjsm_files
typeset -g _jjsm_extra=

# Sets REPLY to the repo with submodules that $1 is in: the nearest
# enclosing git or jj checkout if it has .gitmodules, or else the checkout
# above that if the nearest one is one of its submodules. Fails otherwise,
# so a repo merely nested inside another isn't checked as the outer one.
_jjsm_root() {
  emulate -L zsh
  local d=${1:A} child=
  while :; do
    if [[ -e $d/.git || -d $d/.jj ]]; then
      if [[ -f $d/.gitmodules ]]; then
        if [[ -n $child ]]; then
          _jjsm_parse "$d"
          (( ${_jjsm_paths[(Ie)${child#$d/}]} )) || return 1
        fi
        REPLY=$d
        return 0
      fi
      [[ -n $child ]] && return 1
      child=$d
    fi
    [[ $d == / ]] && return 1
    d=${d:h}
  done
}

# Sets REPLY to the git dir of the checkout at $1; fails when it has none.
_jjsm_gitdir() {
  emulate -L zsh
  local d=$1 gd
  if [[ -d $d/.git ]]; then
    REPLY=$d/.git
  elif [[ -f $d/.git ]]; then
    { { read -r gd || [[ -n $gd ]] } <"$d/.git" } 2>/dev/null
    gd=${gd#gitdir: }
    [[ $gd == /* ]] || gd=$d/$gd
    REPLY=$gd
  else
    return 1
  fi
}

# Sets _jjsm_paths to the submodule paths in $1/.gitmodules, parsing it
# only when it changed (zsh's read is slow: about 0.3 ms for the file).
# This quick parser only decides which files to watch and whether a nested
# checkout is a submodule; _jjsm_check lists the submodules with git config
# itself, so where they disagree a submodule is re-checked late at worst.
_jjsm_parse() {
  emulate -L zsh
  setopt extended_glob
  local root=$1 line
  local quoted='^"(([^"\\]|\\.)*)"'
  local -A st
  zstat -H st -- "$root/.gitmodules" 2>/dev/null || return 0
  local gm="$root $st[inode].$st[mtime]"
  [[ $gm == "$_jjsm_gm" ]] && return 0
  _jjsm_gm=$gm
  _jjsm_paths=()
  # (|| [[ -n $line ]] keeps a last line that has no newline)
  while read -r line || [[ -n $line ]]; do
    # "path = <path>": key in any case, spaces around "=" optional, the
    # value maybe quoted (with \\ and \" escapes), maybe a # or ; comment
    [[ $line == (#i)path[[:space:]]#=* ]] || continue
    line=${line#(#i)path}
    line=${line##[[:space:]]#}
    line=${line#=}
    line=${line##[[:space:]]#}
    if [[ $line =~ $quoted ]]; then
      line=${${match[1]//\\\"/\"}//\\\\/\\}
    else
      line=${line%%[#;]*}
      line=${line%%[[:space:]]#}
    fi
    _jjsm_paths+=("$line")
  done <"$root/.gitmodules"
}

# Appends to _jjsm_files the files whose changes can change the check's
# result for the checkout at $1, the repo itself when $2 is "root" or else
# one of its submodules: git's HEAD and the branch's ref when HEAD is a
# branch; for the repo, jj's working-copy state and git's index (which
# decides the fix suggested); for a submodule, FETCH_HEAD (a fetch can
# bring in a missing pin). git's HEAD is only @-, so it stays put when @
# moves to a commit with the same parent; jj's state changes then too (and
# on every snapshot, so the check after a jj command reruns). Not covered:
# a jj command in another workspace rewriting this one's @ (say a rebase);
# that is seen at the next jj command here. Watching for it would mean
# re-checking after every jj operation in any workspace.
_jjsm_watch() {
  emulate -L zsh
  local d=$1 gd head= fetched common
  [[ $2 == root && -d $d/.jj ]] \
    && _jjsm_files+=("$d/.jj/working_copy/checkout")
  _jjsm_gitdir "$d" || return 0
  gd=$REPLY
  common=$gd
  if [[ -f $gd/commondir ]]; then
    { { read -r common } <"$gd/commondir" } 2>/dev/null
    [[ $common == /* ]] || common=$gd/$common
  fi
  # a reftable repo keeps its refs in reftable/, and a linked worktree's
  # own (its HEAD included) in the worktree's git dir
  _jjsm_files+=("$gd/HEAD" "$common/reftable/tables.list")
  [[ $gd != $common ]] && _jjsm_files+=("$gd/reftable/tables.list")
  # HEAD's contents too: where the filesystem reuses a freed inode at once
  # (ext4, not APFS), two checkouts within a second keep inode and mtime
  { { read -r head } <"$gd/HEAD" } 2>/dev/null && _jjsm_extra+=" $head"
  if [[ $2 == root ]]; then
    _jjsm_files+=("$gd/index")
  else
    # its first line too: git rewrites FETCH_HEAD in place
    _jjsm_files+=("$gd/FETCH_HEAD")
    { { read -r fetched } <"$gd/FETCH_HEAD" } 2>/dev/null \
      && _jjsm_extra+=" $fetched"
  fi
  [[ $head == 'ref: '* ]] || return 0
  _jjsm_files+=("$common/${head#ref: }" "$common/packed-refs")
}

# Sets REPLY to a key that changes whenever a checkout in the repo at $1
# moves or .gitmodules changes. The inode is in it too: git and jj replace
# these files rather than rewrite them, so it changes even within mtime's
# one-second resolution.
_jjsm_state_key() {
  emulate -L zsh
  local root=$1 f p key
  local -A st
  _jjsm_parse "$root"
  _jjsm_files=()
  _jjsm_extra=
  _jjsm_watch "$root" root
  for p in $_jjsm_paths; do _jjsm_watch "$root/$p"; done
  key="$_jjsm_gm"
  for f in $_jjsm_files; do
    if zstat -H st -- "$f" 2>/dev/null; then
      key+=" $st[inode].$st[mtime]"
    else
      key+=" -"
    fi
  done
  REPLY="$key$_jjsm_extra"
}

# Sets REPLY to the commit the submodule at $1 has checked out, or
# "missing" when it isn't checked out.
_jjsm_head() {
  emulate -L zsh
  setopt extended_glob
  local sub=$1 head=
  _jjsm_gitdir "$sub" || { REPLY=missing; return 0 }
  { { read -r head } <"$REPLY/HEAD" } 2>/dev/null
  if [[ $head == [0-9a-f](#c40) ]]; then
    REPLY=$head
  else
    REPLY=$(git -C "$sub" rev-parse HEAD 2>/dev/null) || REPLY=missing
  fi
}

# Sets reply to how the checked-out commit $3 of the submodule at $1
# relates to the pin $2: a kind (ahead, behind, diverged, absent when the
# clone lacks the pin, or unknown when git can't tell) and a phrase.
_jjsm_relation() {
  emulate -L zsh
  local sub=$1 pin=$2 head=$3 behind ahead out
  if ! git -C "$sub" cat-file -e "$pin^{commit}" 2>/dev/null; then
    reply=(absent "and its pin ${pin[1,12]} isn't in the submodule's clone")
    return
  fi
  # commits only the pin has, then commits only the checkout has
  if ! out=$(git -C "$sub" rev-list --left-right --count "$pin...$head" \
      2>/dev/null); then
    reply=(unknown "which git can't compare with its pin ${pin[1,12]}")
    return
  fi
  read -r behind ahead <<<"$out"
  if (( ! behind )); then
    reply=(ahead "$ahead commit(s) ahead of its pin ${pin[1,12]}")
  elif (( ! ahead )); then
    reply=(behind "$behind commit(s) behind its pin ${pin[1,12]}")
  else
    reply=(diverged
      "$ahead commit(s) ahead of and $behind behind its pin ${pin[1,12]}")
  fi
}

# Sets the global _jjsm_links to path -> commit for the submodules in git's
# HEAD ($2 = tree) or index ($2 = index) of the repo at $1; fails when git
# does. (-z: without it git quotes paths with backslashes or quotes.)
_jjsm_gitlinks() {
  emulate -L zsh
  local root=$1 out e
  local -a m
  typeset -gA _jjsm_links
  _jjsm_links=()
  if [[ $2 == index ]]; then
    out=$(git -C "$root" ls-files -s -z -- $_jjsm_paths 2>/dev/null) \
      || return 1
  else
    out=$(git -C "$root" ls-tree -z HEAD -- $_jjsm_paths 2>/dev/null) \
      || return 1
  fi
  for e in ${(0)out}; do
    # "<mode> <sha> <stage>\t<path>" (index), "<mode> <type> <sha>\t<path>"
    m=(${=e%%$'\t'*})
    if [[ $2 == index ]]; then
      if [[ $m[1] == 160000 && $m[3] == 0 ]]; then
        _jjsm_links[${e#*$'\t'}]=$m[2]
      fi
    elif [[ $m[2] == commit ]]; then
      _jjsm_links[${e#*$'\t'}]=$m[3]
    fi
  done
  return 0
}

# Prints one warning line for each submodule of the repo at $1 that isn't
# checked out at its pin. Fails, printing nothing, when the pins can't be
# read, so that callers don't cache that as "in sync".
_jjsm_check() {
  emulate -L zsh
  local root=$1 sm pin head kind rel fix r s sub line out msg
  local -a filesets
  local -A pins idx names
  # the exact list from git config ("submodule.<name>.path\n<path>"
  # entries); the quick parser is only for the prompt's cache key
  local entry
  local -a _jjsm_paths=()
  for entry in ${(0)"$(git config -f "$root/.gitmodules" --null \
      --get-regexp '^submodule\..*\.path$' 2>/dev/null)"}; do
    sm=${entry#*$'\n'}
    _jjsm_paths+=("$sm")
    entry=${entry%%$'\n'*}
    entry=${entry#submodule.}
    names[$sm]=${entry%.path}
  done
  (( $#_jjsm_paths )) || return 0

  if [[ ! -e $root/.git ]]; then
    print -r -- "This jj workspace ($root) has no git checkout, so its" \
      "submodules (${(j:, :)_jjsm_paths}) can't be checked out and won't" \
      "build. Recreate it with \`jj workspace add --colocate\`."
    return 0
  fi
  # the pins: @'s in a jj repo, unless a commit made with git (e.g. a pin
  # bump) hasn't reached jj yet, which happens with the next jj command;
  # until then git's HEAD (which jj's @- will become) has the newer pins
  local use_git=yes git_head parents
  if [[ -d $root/.jj ]]; then
    git_head=$(git -C "$root" rev-parse HEAD 2>/dev/null)
    parents=$(jj --ignore-working-copy -R "$root" log -r @ --no-graph \
      -T 'parents.map(|c| c.commit_id()).join(" ")' 2>/dev/null) || return 1
    [[ -n $git_head && " $parents " != *" $git_head "* ]] || use_git=
  fi
  if [[ -n $use_git ]]; then
    _jjsm_gitlinks "$root" tree || return 1
    pins=("${(@kv)_jjsm_links}")
  else
    for sm in $_jjsm_paths; do
      line=${sm//\\/\\\\}
      filesets+=("root-file:\"${line//\"/\\\"}\"")
    done
    out=$(jj --ignore-working-copy -R "$root" file list -r @ \
      -T 'if(self.file_type() == "git-submodule",
            self.normal_value() ++ "\t" ++ path ++ "\n")' $filesets \
      2>/dev/null) || return 1
    for line in ${(f)out}; do pins[${line#*$'\t'}]=${line%%$'\t'*}; done
  fi

  r=${(q-)root}
  for sm in $_jjsm_paths; do
    pin=${pins[$sm]-}
    if [[ -z $pin ]]; then
      print -r -- "$sm is listed in .gitmodules, but the checked-out" \
        "commit pins no submodule there."
      continue
    fi
    _jjsm_head "$root/$sm"
    head=$REPLY
    [[ $pin == $head ]] && continue
    s=${(q-)sm}
    sub=$root/$sm
    sub=${(q-)sub}
    kind=missing
    if [[ $head != missing ]]; then
      _jjsm_relation "$root/$sm" "$pin" "$head"
      kind=$reply[1] rel=$reply[2]
    fi

    # git submodule update checks out the commit in git's index, which in
    # a colocated jj repo is @-'s; when @ itself changes the pin, only an
    # explicit checkout gets there
    if (( ! $#idx )); then
      _jjsm_gitlinks "$root" index && idx=("${(@kv)_jjsm_links}")
      idx[.]=done
    fi
    if [[ ${idx[$sm]-} == $pin ]]; then
      fix="git -C $r submodule update --init -- $s"
    else
      fix=
      if [[ $kind == missing && -n ${idx[$sm]-} ]]; then
        fix="git -C $r submodule update --init -- $s && "
      elif [[ $kind == missing ]]; then
        # not in git's index (e.g. @- predates the submodule): clone it
        _jjsm_url "$root" "${names[$sm]}"
        if [[ -z $REPLY ]]; then
          print -r -- "$sm isn't checked out (pinned at ${pin[1,12]}), and" \
            ".gitmodules gives no URL to clone it from."
          continue
        fi
        fix="git clone ${(q-)REPLY} $sub && "
      fi
      [[ $kind == absent ]] && fix="git -C $sub fetch origin && "
      fix+="git -C $sub checkout --detach $pin"
    fi

    if [[ $kind == missing ]]; then
      print -r -- "$sm isn't checked out (pinned at ${pin[1,12]})." \
        "To check it out: \`$fix\`."
      continue
    fi
    msg="$sm has ${head[1,12]} checked out, $rel."
    msg+=" To check out the pin: \`$fix\`."
    if [[ $kind != behind ]]; then
      msg+=" To pin the checked-out commit:"
      msg+=" \`git -C $r add -- $s && git -C $r commit\`."
    fi
    print -r -- "$msg"
  done
}

# Sets REPLY to the URL to clone the submodule named $2 in the repo at $1
# from (empty when .gitmodules gives none). A relative URL (./x, ../x) is
# relative to the repo's origin, or to the repo itself when it has none,
# as git submodule resolves it.
_jjsm_url() {
  emulate -L zsh
  local root=$1 name=$2 url base
  REPLY=
  url=$(git config -f "$root/.gitmodules" "submodule.$name.url" 2>/dev/null)
  [[ -n $url ]] || return 0
  if [[ $url == ./* || $url == ../* ]]; then
    base=$(git -C "$root" config remote.origin.url 2>/dev/null) || base=$root
    base=${base%/}
    while :; do
      if [[ $url == ./* ]]; then
        url=${url#./}
      elif [[ $url == ../* ]]; then
        url=${url#../}
        # drop the last component, after a "/" or the ":" of host:path
        if [[ $base == */* ]]; then base=${base%/*}; else base=${base%:*}:; fi
      else
        break
      fi
    done
    [[ $base == *: ]] && url=$base$url || url=$base/$url
  fi
  REPLY=$url
}

# Sets REPLY to $1 as a JSON string.
_jjsm_json() {
  emulate -L zsh
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\t'/\\t}
  s=${s//$'\r'/\\r}
  REPLY="\"$s\""
}

# The PreToolUse hook: prints the warnings for the repo the command runs
# in, as the JSON Claude Code and Codex read additionalContext from. The
# directory is the cwd in the JSON on stdin (falling back to the hook's
# own, which is the same), or Codex's tool_input.workdir when a command
# has its own.
# Each repo's result is cached in a file under the key from
# _jjsm_state_key, so a call runs git and jj only when a checkout moved.
_jjsm_hook() {
  emulate -L zsh
  local input dir=$PWD root key out cache line field
  IFS= read -r -d '' input
  # the input's cwd (both send it), then Codex's per-command workdir
  local value='[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)"'
  for field in cwd workdir; do
    [[ $input =~ "\"$field\"$value" ]] || continue
    line=${match[1]//\\\//\/}
    line=${line//\\\"/\"}
    line=${line//\\\\/\\}
    [[ $line == /* ]] || line=$dir/$line
    [[ -d $line ]] && dir=$line
  done
  _jjsm_root "$dir" || return 0
  root=$REPLY
  _jjsm_state_key "$root"
  key=$REPLY
  cache=${XDG_CACHE_HOME:-$HOME/.cache}/jj-submodule-check/${root//\//%}
  if [[ -f $cache ]] && { IFS= read -r line } <"$cache" \
    && [[ $line == $key ]]
  then
    out=${"$(<"$cache")"#*$'\n'}
    [[ $out == "$line" ]] && out=
  else
    out=$(_jjsm_check "$root") || return 0
    # write then rename, so a concurrent hook never reads a partial file
    mkdir -p "${cache:h}" \
      && print -r -- "$key"$'\n'"$out" >|"$cache.$$" \
      && zf_mv -f "$cache.$$" "$cache"
  fi
  [[ -n $out ]] || return 0
  _jjsm_json "Submodule check in $root: $out"
  print -r -- "{\"hookSpecificOutput\": {\"hookEventName\": \"PreToolUse\"," \
    "\"additionalContext\": $REPLY}}"
}

# Entry point when this file is run as a program.
_jjsm_main() {
  emulate -L zsh
  case ${1-} in
    --hook)
      # never block or disturb the agent because the check itself failed
      _jjsm_hook 2>/dev/null
      return 0
      ;;
    -h|--help)
      print -r -- "usage: jj-submodule-check.zsh [dir]   warn about each" \
        "submodule of the repo around dir that isn't at its pin" \
        $'\n'"       jj-submodule-check.zsh --hook  the same as a" \
        "PreToolUse hook for Claude Code and Codex"
      ;;
    *)
      _jjsm_root "${1:-.}" || return 0
      if ! _jjsm_check "$REPLY"; then
        print -r -- "jj-submodule-check: couldn't read the submodule pins" \
          "of $REPLY: a git or jj command failed" >&2
        return 1
      fi
      ;;
  esac
}

_jjsm_precmd() {
  emulate -L zsh
  if ! _jjsm_root "$PWD"; then
    _jjsm_key=
    return 0
  fi
  local root=$REPLY line
  _jjsm_state_key "$root"
  if [[ "$root $REPLY" != "$_jjsm_key" ]]; then
    local key="$root $REPLY"
    # take the result and key only when the check finished: an interrupted
    # or failed check keeps the previous warnings and reruns next prompt
    # (but never another repo's warnings)
    local out
    if out=$(_jjsm_check "$root" 2>/dev/null); then
      _jjsm_out=$out
      _jjsm_key=$key
    elif [[ $root != "$_jjsm_out_root" ]]; then
      _jjsm_out=
    fi
    _jjsm_out_root=$root
  fi
  [[ -n $_jjsm_out ]] || return 0
  print -P '%F{yellow}submodules out of sync:%f' >&2
  for line in "${(@f)_jjsm_out}"; do print -r -- "  $line" >&2; done
}

if [[ $ZSH_EVAL_CONTEXT == toplevel ]]; then
  # run as a program; agents launched from the GUI may lack Homebrew's
  # bin, where jj is
  [[ -d /opt/homebrew/bin ]] && path=(/opt/homebrew/bin $path)
  _jjsm_main "$@"
  exit
fi
_jjsm_register() {
  emulate -L zsh
  typeset -ga precmd_functions
  (( ${precmd_functions[(I)_jjsm_precmd]} )) \
    || precmd_functions+=(_jjsm_precmd)
}
[[ -o interactive ]] && _jjsm_register
