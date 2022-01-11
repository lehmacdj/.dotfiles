silent! augroup! GitConfigHighlight
augroup GitConfigHighlight
    autocmd!
    autocmd BufNewFile,BufRead *gitconfig* set filetype=gitconfig
augroup END
