setlocal spell
setlocal tw=80

let b:markdown_trailing_space_rules = 1

" utilities for compiling to pdf
nmap <buffer> <LocalLeader>pc :!pandoc --pdf-engine=xelatex % -o %:r.pdf<CR>
nmap <buffer> <LocalLeader>po :!open %:r.pdf<CR>

if filereadable('neuron.dhall')
    " neuron folgezettel mappings
    " for some reason none of these mappings work when put as nnoremap's?
    nmap <buffer> ]z :<C-U>call neuron#move_history(1)<CR>
    nmap <buffer> [z :<C-U>call neuron#move_history(-1)<CR>

    nmap <buffer> <C-]> <Plug>EditZettelUnderCursor
    nmap <buffer> <Leader>o <Plug>EditZettelSelect
    nmap <buffer> <LocalLeader>b <Plug>EditZettelBacklink

    nmap <buffer> <Leader>/ <Plug>EditZettelSearchContent
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
