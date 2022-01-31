#!/usr/bin/env bash
if starship help >/dev/null 2>&1; then
  eval "$(starship init bash)"
  eval "$(starship completions bash)"
else
  export PS1="\w> "
fi
