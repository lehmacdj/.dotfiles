" Wrap lines at 80 automatically
" setlocal textwidth=80

" Make c a new surround command for a latex command
" e.g. ysapc[arg] would surround a paragraph like \arg{[paragraph]}
let g:surround_{char2nr('c')} = "\\\1command\1{\r}"

setlocal spell

nnoremap <LocalLeader>o :!open %:r.pdf<CR><CR>

nnoremap <LocalLeader>m :make<CR>

" let b:deoplete_omni_input_patterns = '\\(?:'
"     \ .  '\w*cite\w*(?:\s*\[[^]]*\]){0,2}\s*{[^}]*'
"     \ . '|\w*ref(?:\s*\{[^}]*|range\s*\{[^,}]*(?:}{)?)'
"     \ . '|hyperref\s*\[[^]]*'
"     \ . '|includegraphics\*?(?:\s*\[[^]]*\]){0,2}\s*\{[^}]*'
"     \ . '|(?:include(?:only)?|input)\s*\{[^}]*'
"     \ . '|\w*(gls|Gls|GLS)(pl)?\w*(\s*\[[^]]*\]){0,2}\s*\{[^}]*'
"     \ . '|includepdf(\s*\[[^]]*\])?\s*\{[^}]*'
"     \ . '|includestandalone(\s*\[[^]]*\])?\s*\{[^}]*'
"     \ . ')'
