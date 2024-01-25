setlocal spell
setlocal nosmartindent " without this for/while/if etc. trigger new indent level

" make breakindent recognize markdown lists
let &formatlistpat = '^\s*[-+*]\( \[ \]\)\?\s*\|\s*\d\+\.\s*'

" let b:markdown_trailing_space_rules = 0

" utilities for compiling to pdf
nmap <buffer> <LocalLeader>c :!pandoc --pdf-engine=xelatex % -o %:r.pdf<CR>
nmap <buffer> <LocalLeader>o :!open %:r.pdf<CR>

xmap <buffer> <expr> p config#visual_magic_markdown_link_paste()

" paste link around visually selected text, using <Leader>p instead of
" <LocalLeader>p because it's easier to type and I don't currently have any
" conflicts
" Keeping this around because it's technically one keypress shorter and again
" I don't have any conflicts yet.
xmap <buffer> <Leader>p S]%a()<Esc>"+PF]%

" Stuff for softwrapping
setlocal wrap
setlocal linebreak
setlocal showbreak=
nnoremap j gj
nnoremap k gk
nnoremap $ g$
xnoremap j gj
xnoremap k gk
xnoremap $ g$
" leave a way to get true $
nnoremap g$ $
xnoremap g$ $
nnoremap 0 g0
xnoremap 0 g0

if filereadable('neuron.dhall')
    " I don't want git gutter for my notes because it will make me think about
    " commiting things too often
    silent! GitGutterDisable

    " neuron folgezettel mappings
    " for some reason none of these mappings work when put as nnoremap's?
    nmap <buffer> ]z :<C-U>call neuron#move_history(1)<CR>
    nmap <buffer> [z :<C-U>call neuron#move_history(-1)<CR>

    nmap <buffer> <LocalLeader>o :!open http://localhost:8080/%:t:r.html<CR>

    " This is probably subsumed by the LSP already, just keeping it commented
    " out in case I end up wanting to re-enable it because I discover it's
    " broken later.
    " nmap <buffer> <C-]> <Plug>EditZettelUnderCursor
    nmap <buffer> <Leader>o <Plug>EditZettelSelect
    nmap <buffer> <LocalLeader>b <Plug>EditZettelBacklink

    nmap <buffer> <LocalLeader>g/ <Plug>EditZettelSearchContentUnderCursor

    nmap <buffer> <LocalLeader>n <Plug>EditZettelNew
    " these are <LocalLeader>d to mean define, which is kind of what it means to
    " create a new zettel for a word
    nmap <buffer> <LocalLeader>d :<C-U>call neuron#edit_zettel_new_from_cword(0)<CR>
    xmap <buffer> <LocalLeader>d <esc>:<C-U>call neuron#edit_zettel_new_from_visual(0)<CR>

    " two variants of each first [[ ]] links then [[[ ]]] links
    nmap <buffer> <LocalLeader>s <Plug>InsertZettelSelect
    " mnemonic append, also because it is a key right next to s
    nmap <buffer> <LocalLeader>a <Plug>InsertZettelLast

    nmap <buffer> <LocalLeader>r <Plug>NeuronRefreshCache

    nmap <buffer> <LocalLeader>ta <Plug>TagsAddNew
    nmap <buffer> <LocalLeader>ts <Plug>TagsAddSelect
    nmap <buffer> <LocalLeader>t/ <Plug>TagsZettelSearch
endif
