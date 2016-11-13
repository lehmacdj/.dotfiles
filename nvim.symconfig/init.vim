" initialize $VIMHOME to the configuration home
let $VIMHOME=expand('<sfile>:p:h')

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
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set smarttab
set autoread

" display stuff
set nohlsearch
set scrolloff=4
set showcmd
set number

" searching
set magic
set ignorecase
set smartcase
set incsearch

" buffers
set hidden

" completion
set omnifunc=syntaxcomplete#Complete
inoremap <C-@> <C-x><C-o>

" escape mapping
inoremap jk <ESC>

nnoremap Y y$

" map leader
let mapleader=" "

nnoremap <Leader>ev :split $MYVIMRC<CR>
nnoremap <Leader>sv :source $MYVIMRC<CR>
nnoremap <Leader>ep :split $VIMHOME/plugins.vim<CR>
nnoremap <expr> <Leader>ef ':split ~/.vim/ftplugin/' . &filetype . '.vim<CR>'
noremap <Leader>t<Space> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

tnoremap <C-\>j <C-\><C-n><C-w><C-j>
tnoremap <C-\>k <C-\><C-n><C-w><C-k>
tnoremap <C-\>l <C-\><C-n><C-w><C-l>
tnoremap <C-\>h <C-\><C-n><C-w><C-h>

" finally load local vim configuration if it exists
if filereadable("$VIMHOME/local.vim")
    source $VIMHOME/local.vim
endif
