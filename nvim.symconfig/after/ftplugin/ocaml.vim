" Make tabstop smaller
setlocal tabstop=2
setlocal shiftwidth=2

setlocal iskeyword+='

" Bindings for merlin
nnoremap <LocalLeader>m :GotoDotMerlin<CR>
nnoremap <LocalLeader>d :MerlinDocument<CR>
nnoremap <LocalLeader>g :MerlinGrowEnclosing<CR>

" enable merlin completion
let b:deoplete_omni_input_patterns = ['[^. *\t]\.\w*','[A-Za-z_]\w*','#']
let b:deoplete_sources = ['buffer', 'omni']

" forward merlin data to neomake
function! g:OCaml_Merlin_GenerateArgs()
    let s:errors = merlin#ErrorLocList()
    return '-ne "'.repeat('e\n', len(s:errors)).'\c"'
endfunction

function! g:OCaml_Merlin_PutErrors(entry) abort
    if !exists('s:errors')
        let a:entry.valid = 0
    else
        let l:err = remove(s:errors, 0)
        let a:entry.col = l:err.col
        let a:entry.lnum = l:err.lnum
        let a:entry.text = l:err.text
        let a:entry.pattern = l:err.pattern
        let a:entry.type = l:err.type
        let a:entry.bufnr = l:err.bufnr
        let a:entry.nr = l:err.nr
        let a:entry.valid = 1
    endif
endfunction

let g:neomake_ocaml_merlin_maker = {
    \ 'exe' : 'echo',
    \ 'args' : function('g:OCaml_Merlin_GenerateArgs'),
    \ 'errorfmt' : '%E%m',
    \ 'postprocess' : function('g:OCaml_Merlin_PutErrors')
    \ }

" let g:neomake_ocaml_enabled_makers = ['merlin']
