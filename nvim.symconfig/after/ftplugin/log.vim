function HideBeforeGreater()
    call matchadd('Conceal', '^.*> ')
    set conceallevel=3
endfunction

nnoremap <buffer> <LocalLeader>h> :call HideBeforeGreater()<CR>
