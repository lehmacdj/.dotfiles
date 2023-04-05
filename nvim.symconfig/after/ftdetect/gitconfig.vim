silent! augroup! GitConfigHighlight
augroup GitConfigHighlight
    autocmd!
    autocmd BufNewFile,BufRead *gitconfig* setlocal filetype=gitconfig
    autocmd BufNewFile,BufRead *git*/*config* setlocal filetype=gitconfig
augroup END
