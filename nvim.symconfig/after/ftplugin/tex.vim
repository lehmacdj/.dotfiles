" Wrap lines at 80 automatically
" setlocal textwidth=80

" Make c a new surround command for a latex command
" e.g. ysapc[arg] would surround a paragraph like \arg{[paragraph]}
let g:surround_{char2nr('c')} = "\\\1command\1{\r}"

setlocal spell

" soft wrap instead of hard wrapping in latex mode
setlocal wrap linebreak
nnoremap <buffer> j gj
nnoremap <buffer> k gk

nnoremap <buffer> <LocalLeader>o :!open %:r.pdf<CR><CR>
nnoremap <buffer> <LocalLeader>m :make<CR>
nnoremap <buffer> <LocalLeader>s :VimtexCompile<CR>
nnoremap <buffer> <LocalLeader>c :!md5 %:r.pdf<CR>

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
