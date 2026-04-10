setlocal spell
setlocal nosmartindent " without this for/while/if etc. trigger new indent level
setlocal conceallevel=2 " hide links/html comments

" toggle markdown comment visibility (unimpaired style)
nnoremap <buffer> [oc <Cmd>lua require'my.markdown'.hide_comments()<CR>
nnoremap <buffer> ]oc <Cmd>lua require'my.markdown'.show_comments()<CR>
nnoremap <buffer> yoc <Cmd>lua if vim.g.show_markdown_comments then require'my.markdown'.hide_comments() else require'my.markdown'.show_comments() end<CR>

" toggle markdown image preview
nnoremap <buffer> [op <Cmd>lua require'image'.disable()<CR>
nnoremap <buffer> ]op <Cmd>lua require'image'.enable()<CR>
nnoremap <buffer> yop <Cmd>lua if require("image").is_enabled() then require'image'.disable() else require'image'.enable() end<CR>

nnoremap <LocalLeader>i <Cmd>edit ~/wiki/index.md<CR>

" make breakindent recognize markdown lists
let &formatlistpat = '^\(>\)\?\s*[-+*]\( \[[ x]\]\)\?\s*\|^\s*\d\+\.\s*'

setlocal comments=b:*,b:-,b:+,bn:> " allow nesting > (compared w/ markdown.vim)
" insert/join "comment" (i.e. list) leaders automatically
" return, o (o/O in normal mode), and when joining lines
" I find this mildly annoying for lists, but it's really nice for > quotes
" I wish there were a way to still keep `j` for any kind of comment, but only
" ro for `>`
setlocal formatoptions+=roj

" perhaps worth looking into https://github.com/dkarter/bullets.vim for
" automatically making bullets work as I would desire

" convert a wiki style image like `![[file name.png]]` into a standard
" markdown link like `![|](<images/file name.png>)` placing the cursor at the
" pipe symbol and entering insert mode so that I can easily add alt text.
" depends on: vim-surround
nmap <buffer> <LocalLeader>c F!llds]cs])aimages/<esc>ysi)>hi[]<esc>i

call my#markdown#setup_softwrap()

augroup markdown_targets
  autocmd!
  " Extend argument text objects to treat | as a separator inside [[...]].
  " This makes ia/aa work on parts of wikilinks like [[slug|Title]].
  autocmd User targets#mappings#user call targets#mappings#extend({
    \ 'a': {'argument': [
    \   {'o': '[[]', 'c': '[]]', 's': '[|,]'},
    \   {'o': '(', 'c': ')', 's': ','},
    \ ]}
    \ })
augroup END

if filereadable('neuron.dhall')
    " I don't want git gutter for my notes because it will make me think about
    " commiting things too often
    silent! GitGutterDisable

    nmap <buffer> <LocalLeader>n <Plug>EditZettelNew
    " these are <LocalLeader>d to mean define, which is kind of what it means to
    " create a new zettel for a word
    nmap <buffer> <LocalLeader>d <Cmd>call neuron#edit_zettel_new_from_cword(0)<CR>
    xmap <buffer> <LocalLeader>d <esc>:<C-U>call neuron#edit_zettel_new_from_visual(0)<CR>

    " recover the file comparing swap with what is currently on the disk
    nnoremap <buffer> <LocalLeader>r <Cmd>w %~<CR>:e!<CR>:diffthis<CR>:vsp %~<CR>:diffthis<CR>

    " janky macro that creates a new zettel based on a visual selection which
    " becomes the body of the new zettel
    " this macro lets me feel like an emacs user because it starts with mX, lol
    xmap <buffer> <LocalLeader>n mX"zd<esc>\nkVG"zpO- [[<C-r>=expand('%:t:r')<CR>]]<esc>dd:w<CR>'XP
endif
