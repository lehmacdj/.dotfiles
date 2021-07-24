" initialize $VIMHOME to the configuration home
let $VIMHOME=expand('<sfile>:p:h')

" Leader mappings
" leader needs to be set before loading plugins, otherwise mapping made by
" plugins don't use the leader
let mapleader=" "
let maplocalleader = "\\"

" load plugins
if filereadable($VIMHOME."/plugins.vim")
    source $VIMHOME/plugins.vim
endif

" make syntax work
filetype plugin indent on
syntax enable

" improve vim command completion
set wildmode=longest:full,full
set wildmenu

" tabs and stuff
set tabstop=2
set shiftwidth=2
set expandtab
set autoindent
set smartindent
set smarttab

" ui
set termguicolors
set background=dark
silent! colorscheme solarized
set mouse=a
set scrolloff=4
set showcmd
set number
set nohlsearch
set laststatus=2
set belloff=all
let g:airline_powerline_fonts = 1
let g:airline#extensions#whitespace#mixed_indent_algo = 2
let g:netrw_liststyle = 3

" fix delay when exiting insert mode
if !has('nvim')
    set noesckeys
endif

" searching
set magic
set ignorecase
set smartcase
set incsearch
if has('nvim')
    set inccommand=split
end

" buffers
set hidden

" history
set undolevels=10000
set undofile
if has('nvim')
    " maximum terminal scrollback
    set scrollback=100000
end

" formatting
" delete comment character when joining lines
set formatoptions+=jn
set nojoinspaces

" deoplete
if has('nvim')
    " let g:deoplete#enable_at_startup = 1
    " let g:deoplete#enable_smart_case = 1
    " autocmd CmdwinEnter * let b:deoplete_sources = ['buffer']
    " " make backspace close the popup window
    " inoremap <expr> <C-h> deoplete#smart_close_popup()."\<C-h>"
    " inoremap <expr> <BS>  deoplete#smart_close_popup()."\<C-h>"
    " inoremap <expr> <C-Space> deoplete#manual_complete()
else
    set omnifunc=syntaxcomplete#Complete
    " inoremap <NUL> <C-x><C-o>
    set completeopt=longest,menuone
    inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
    inoremap <expr> <C-n> pumvisible() ? '<C-n>' :
      \ '<C-n><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'
    inoremap <expr> <NUL> pumvisible() ? '<C-n>' :
      \ '<C-x><C-o><C-n><C-p><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'
end

" neomake
autocmd BufWinEnter,BufWritePost * Neomake

" Make backspace behave the way I expect
set backspace=indent,eol,start

" Global mappings
" Easy macro-replay
nnoremap Q @q
" make Y more logical
nnoremap Y y$
" align lines
nmap ga <Plug>(EasyAlign)
xmap ga <Plug>(EasyAlign)
" toggle background color
nnoremap <F3> :set background!<CR>
if has('nvim')
    " navigation from terminal
    tnoremap <C-\>j <C-\><C-n><C-w><C-j>
    tnoremap <C-\>k <C-\><C-n><C-w><C-k>
    tnoremap <C-\>l <C-\><C-n><C-w><C-l>
    tnoremap <C-\>h <C-\><C-n><C-w><C-h>
end

" Edit vimrc
nnoremap <Leader>ev :split $MYVIMRC<CR>
" Edit plugins
nnoremap <Leader>ep :split $VIMHOME/plugins.vim<CR>
" Edit filetype file
nnoremap <expr> <Leader>ef ':split '.$VIMHOME.'/after/ftplugin/'.&filetype.'.vim<CR>'
" Edit syntax file
nnoremap <expr> <Leader>es ':split '.$VIMHOME.'/syntax/'.&filetype.'.vim<CR>'
" Edit detection file
nnoremap <expr> <Leader>ed ':split '.$VIMHOME.'/after/ftdetect/'.&filetype.'.vim<CR>'
" Edit config file
nnoremap <Leader>ec :split $VIMHOME/autoload/config.vim<CR>
" Source vimrc
nnoremap <Leader>sv :source $MYVIMRC<CR>
" Install plugins
nnoremap <Leader>ip :PlugInstall<CR>
" Fuzzy file open
nnoremap <Leader>o :FZF<CR>
" Fuzzy ag
nnoremap <Leader>/ :Ag<CR>
" Trim whitespace
noremap <Leader>t<Space> :call config#StripWhitespace()<CR>
" Generate ctags
nnoremap <Leader>mt :!ctags -R .<CR><CR>
" Toggle hlsearch
nnoremap <Leader>th :set hlsearch!<CR>
" Open buffer list
nnoremap <Leader>b :Buffers<CR>
" run the last normal mode command
nnoremap <Leader>: :<Up><CR>
xnoremap <Leader>: :<Up><CR>
" run the last command in a terminal buffer
nnoremap <Leader><C-k> i<C-k><Return><C-\><C-n>

" toggle colorcolumn with <space>8
set colorcolumn=81
nnoremap <Leader>8 :call config#ToggleColorColumn()<CR>

" Spelling related things
if &spell
    nnoremap <Leader>z 1z=

    nnoremap <Leader>sc :call config#CompileSpellFiles()<CR>

    " Spelling corrections
    abbreviate teh the
end

" finally load local vim configuration if it exists
if filereadable($VIMHOME."/local.vim")
    nnoremap <Leader>eL :split $VIMHOME/local.vim<CR>
    source $VIMHOME/local.vim
endif
