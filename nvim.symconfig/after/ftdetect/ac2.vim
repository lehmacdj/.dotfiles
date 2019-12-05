silent! augroup! Ac2Highlight
augroup Ac2Highlight
    autocmd BufNewFile,BufRead *.ac2 set filetype=jsonnet
augroup END
