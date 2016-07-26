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

" splits
set splitright

" completion
set omnifunc=syntaxcomplete#Complete
inoremap <C-@> <C-x><C-o>

" escape mapping
inoremap jk <ESC>

" map leader
let mapleader=" "

" finally load local vim configuration if it exists
if filereadable("$VIMHOME/local.vim")
    source $VIMHOME/local.vim
endif
