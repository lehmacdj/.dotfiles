nnoremap <buffer> <leader>c :!pdflatex %<cr>

setlocal textwidth=80
let g:surround_{char2nr('c')} = "\\\1command\1{\r}"
