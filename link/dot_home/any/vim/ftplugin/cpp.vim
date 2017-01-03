let g:syntastic_cpp_compiler = 'g++'
let g:syntastic_cpp_compiler_options = ' -std=c++11 -stdlib=libc++'

function! CppGetCounterPart()
    if expand('%:e') == 'cpp'
        let l:name = expand('%:r') . '.h'
    elseif expand('%:e') == 'h'
        let l:name = expand('%:r') . '.cpp'
    endif
    return l:name
endfunction

nnoremap <expr> <LocalLeader>s ':edit ' . CppGetCounterPart() . '<CR>'
