setlocal spell
setlocal nosmartindent " without this for/while/if etc. trigger new indent level

" make breakindent recognize markdown lists
let &formatlistpat = '^\s*[-+*]\( \[[ x]\]\)\?\s*\|^\s*\d\+\.\s*'

" perhaps worth looking into https://github.com/dkarter/bullets.vim for
" automatically making bullets work as I would desire

" utilities for compiling to pdf
nmap <buffer> <LocalLeader>c :!pandoc --pdf-engine=xelatex % -o %:r.pdf<CR>
nmap <buffer> <LocalLeader>o :!open %:r.pdf<CR>

" convert a wiki style image like `![[file name.png]]` into a standard
" markdown link like `![|](<images/file name.png>)` placing the cursor at the
" pipe symbol and entering insert mode so that I can easily add alt text.
" depends on: vim-surround
nmap <buffer> <LocalLeader>ic F!llds]cs])aimages/<esc>ysi)>hi[]<esc>i

xmap <buffer> <expr> p my#misc#visual_magic_markdown_link_paste()

" Stuff for softwrapping
setlocal wrap
setlocal linebreak
setlocal showbreak=
setlocal colorcolumn=
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

    " nmap <buffer> <LocalLeader>r <Plug>NeuronRefreshCache

    nmap <buffer> <LocalLeader>ta <Plug>TagsAddNew
    nmap <buffer> <LocalLeader>ts <Plug>TagsAddSelect
    nmap <buffer> <LocalLeader>t/ <Plug>TagsZettelSearch

    nnoremap <buffer> <LocalLeader>r :w %~<CR>:e!<CR>:diffthis<CR>:vsp %~<CR>:diffthis<CR>

    " janky macro that creates a new zettel based on a visual selection which
    " becomes the body of the new zettel
    " this macro lets me feel like an emacs user because it starts with mX, lol
    xmap <buffer> <LocalLeader>n mX"zd<esc>\nkVG"zpO- [[<C-r>=expand('%:t:r')<CR>]]<esc>dd:w<CR>'XP
endif
