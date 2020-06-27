silent! augroup! Ac2Highlight
augroup Ac2Highlight
    " .ac2 is a proprietary file extension for azure config in identity at
    " Microsoft. It is basically a jsonnet file
    autocmd BufNewFile,BufRead *.ac2 set filetype=jsonnet
augroup END
