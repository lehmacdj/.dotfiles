" Wrap lines at 80 automatically
setlocal textwidth=80

" Make c a new surround command for a latex command
" e.g. ysapc[arg] would surround a paragraph like \arg{[paragraph]}
let g:surround_{char2nr('c')} = "\\\1command\1{\r}"

setlocal spell

nnoremap <LocalLeader>op :!open %:r.pdf<CR><CR>
