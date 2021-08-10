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
augroup override_solarized_Pmenu
  autocmd!
  " for some reason coc.nvim doesn't do well with the default value for this
  " which uses gui=reverse. This makes it so that we don't need to use
  " gui=reverse but still get pretty much the same colorscheme
  function s:FixPmenu()
    if &background ==# 'dark'
      silent! hi Pmenu ctermfg=13 ctermbg=0 gui=none guifg=#839496 guibg=#073642
    else
      silent! hi Pmenu ctermbg=0 ctermfg=225 gui=none guibg=#eee8d5 guifg=#657b83
    endif
  endfunction
  autocmd ColorScheme * call <SID>FixPmenu()
augroup END
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
if has('nvim')
    augroup neovim_terminal
        autocmd!

        " terminal with scrolloff causes weird behavior with TUI programs or
        " even just when using C-l to clear screen; line numbers seem
        " redundant for terminals too
        autocmd TermOpen * setlocal nonumber norelativenumber
        " don't set scrolloff because it doesn't have a local value scrolloff=0
    augroup END
endif
if has("nvim-0.5.0") || has("patch-8.1.1564")
  set signcolumn=number
endif

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
if !has('nvim')
    " move history files to XDG_DATA_HOME
    let s:data_dir = exists('$XDG_DATA_HOME') ? $XDG_DATA_HOME.'/vim' : $HOME.'/.local/share/vim'
    let s:undo_dir = s:data_dir.'/undo'
    let s:swap_dir = s:data_dir.'/swap'
    call system('mkdir -p '.s:undo_dir)
    call system('mkdir -p '.s:swap_dir)
    let &directory = s:swap_dir
    let &undodir = s:undo_dir
end
if has('nvim')
    " maximum terminal scrollback
    set scrollback=100000
end

" formatting
" delete comment character when joining lines
set formatoptions+=jn
set nojoinspaces

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
" Fuzzy rg
nnoremap <Leader>/ :Rg<CR>
" Trim whitespace
noremap <Leader>t<Space> :call config#StripWhitespace()<CR>
" Generate ctags
nnoremap <Leader>mt :!ctags -R .<CR><CR>
" Toggle hlsearch
nnoremap <Leader>th :set hlsearch!<CR>
" Open buffer list
nnoremap <Leader>b :Buffers<CR>
" Delete buffers from buffer list interactively
nnoremap <Leader>db :call config#InteractiveBufDelete()<CR>
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

" indent text objects copied from here:
" https://vim.fandom.com/wiki/Indent_text_object
onoremap <silent>ai :<C-U>call config#IndentTextObject(0)<CR>
onoremap <silent>ii :<C-U>call config#IndentTextObject(1)<CR>
vnoremap <silent>ai :<C-U>call config#IndentTextObject(0)<CR><Esc>gv
vnoremap <silent>ii :<C-U>call config#IndentTextObject(1)<CR><Esc>gv

" finally load local vim configuration if it exists
if filereadable($VIMHOME."/local.vim")
    nnoremap <Leader>eL :split $VIMHOME/local.vim<CR>
    source $VIMHOME/local.vim
endif
