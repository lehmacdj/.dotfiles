silent! augroup! XiHighlight
augroup XiHighlight
    autocmd!
    autocmd BufNewFile,BufRead *.xi set filetype=xi
    autocmd BufNewFile,BufRead *.ixi set filetype=xi
augroup END
