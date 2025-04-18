" initialize $VIMHOME to the configuration home
let $VIMHOME=expand('<sfile>:p:h')

" Leader mappings
" leader needs to be set before loading plugins, otherwise mapping made by
" plugins don't use the leader
let mapleader = ' '
let maplocalleader = '\'

" load plugins
if filereadable($VIMHOME.'/plugins.vim')
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

" ignore whitespace when diffing
set diffopt+=iwhiteall

" make text wrapping smarter
set breakindent
set breakindentopt+=list:-1
" set formatlistpat in filetype config files to define lists for that filetype
" e.g. in markdown.vim we define something like:
" let &formatlistpat = '^\s*[-+*]\( \[ \]\)\?\s*\|\s*\d\+\.\s*'
set formatoptions+=m " make character wrapping with kanji work better

" ui
set termguicolors
set background=dark
augroup override_solarized
  autocmd!
  " solarzied color scheme looks ugly for floating menus without this change
  function s:FixPmenu()
    if &background ==# 'dark'
      silent! hi Pmenu ctermfg=13 ctermbg=0 gui=none guifg=#839496 guibg=#073642
    else
      silent! hi Pmenu ctermbg=0 ctermfg=225 gui=none guifg=#657b83 guibg=#eee8d5
    endif
  endfunction
  autocmd ColorScheme * call <SID>FixPmenu()
  " SpellBad with gui colorscheme is too loud, this makes the squiggle the
  " same color as primary text
  function s:FixSpellBad()
      if &background ==# 'dark'
          silent! hi SpellBad guisp=#839496 " solarized base0
      else
          silent! hi SpellBad guisp=#657b83 " solarized base00
      endif
    endfunction
  autocmd ColorScheme * call <SID>FixSpellBad()
augroup END
silent! colorscheme NeoSolarized
set mouse=a
set scrolloff=4
set showcmd
set number
set nohlsearch
set laststatus=2
set belloff=all
set updatetime=100 " make popups appear quickly
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
xnoremap Q @q
" always yank to system clipboard
nnoremap y "+y
" special cased to make Y more logical (matching C/D)
nnoremap Y "+y$
vnoremap y "+y
nnoremap yy "+yy
" make gq use gw which is pretty much just a better version of gq
nnoremap gq gw
nnoremap gqq gww
xnoremap gq gw
" TODO: would like to use these but they don't use the same relative directory
" when opening the file. It should be relative to the file with the reference
" not vim's current directory
" " make gf / <C-w><C-f> automatically create new files
" nnoremap gf :e <cfile><CR>
" nnoremap <C-w>f :split <cfile><CR>
" nnoremap <C-w><C-f> :split <cfile><CR>
if has('nvim')
    " navigation from terminal
    tnoremap <C-\>j <C-\><C-n><C-w><C-j>
    tnoremap <C-\>k <C-\><C-n><C-w><C-k>
    tnoremap <C-\>l <C-\><C-n><C-w><C-l>
    tnoremap <C-\>h <C-\><C-n><C-w><C-h>
end

" Editting / meta vim config
" Edit vimrc
nnoremap <Leader>ev :split $MYVIMRC<CR>
" Edit plugins
nnoremap <Leader>ep :split $VIMHOME/plugins.vim<CR>
" Edit filetype file
nnoremap <expr> <Leader>ef ':split '.$VIMHOME.'/after/ftplugin/'.&filetype.'.vim<CR>'
" Edit syntax file
nnoremap <Leader>es :call my#misc#EditSyntaxFile()<CR>
" Edit detection file
nnoremap <expr> <Leader>ed ':split '.$VIMHOME.'/after/ftdetect/'.&filetype.'.vim<CR>'
" Edit a lazy loaded viml/lua config file
nnoremap <Leader>ec :lua require('my.telescope').find_vim_config_files()<CR>
" Edit something in my dotfiles
nnoremap <Leader>e. :lua require('my.telescope').find_dotfiles()<CR>
" Edit the local vim config (which may or may not exist, sourced below)
nnoremap <Leader>el :split $VIMHOME/local.vim<CR>
" Source vimrc
nnoremap <Leader>sv :source $MYVIMRC<CR>

augroup vim_config_autorefresh
    autocmd!
    " for any file prefixed by autoload/config reload it when saving
    " in particular this includes $VIMHOME/autoload/my/misc.vim which is my
    " main config file for functions. Reloading it otherwise is tedious.
    autocmd BufWritePost $VIMHOME/autoload/**/*.vim :source <afile>

    " for any lua file in $VIMHOME/lua reload it when saving
    autocmd BufWritePost $VIMHOME/lua/**/*.lua call v:lua.require'my.misc'.rerequire(expand('<afile>'))
augroup END

" Delete buffers from buffer list interactively
nnoremap <Leader>db :call my#misc#InteractiveBufDelete()<CR>
" run the last normal mode command
nnoremap <Leader>: :<Up><CR>
xnoremap <Leader>: :<Up><CR>
" run the last command in a terminal buffer
nnoremap <Leader><C-k> i<C-k><Return><C-\><C-n>

" smarter tag following
nnoremap <C-]> :call my#misc#smart_goto()<CR>
" testing out using this for goto references since I barely use :tselect
" nnoremap g] :call my#misc#smart_goto_select()<CR>
nnoremap g<C-]> :call my#misc#smart_goto()<CR>

" toggle colorcolumn with <space>8
set colorcolumn=81
nnoremap <Leader>8 :call my#misc#ToggleColorColumn()<CR>

" Trim whitespace / this can be turned off by disabling auto-formatting
augroup trim_whitespace
    autocmd!
    autocmd BufWritePre * :call my#misc#StripWhitespace()
augroup END

" toggle autoformatting on save in style of unimpaired.vim
let g:do_autoformat = 1
nnoremap [o= :lua require'my.misc'.enable_autoformat()<CR>
nnoremap ]o= :lua require'my.misc'.disable_autoformat()<CR>
nnoremap yo= :<C-U>lua <C-R>=g:do_autoformat
    \ ? "require'my.misc'.disable_autoformat()"
    \ : "require'my.misc'.enable_autoformat()"<CR><CR>

" Spelling related things
nnoremap <Leader>z 1z=
" automatically commit spellfile changes
nnoremap zg :call my#misc#commit_dictionary_word()<CR>
xnoremap zg :call my#misc#commit_dictionary_word(visualmode())<CR>
" TODO: asynchronously compile spell files on startup
nnoremap <Leader>sc :call my#misc#CompileSpellFiles()<CR>
" Spelling corrections
abbreviate teh the

" indent text objects copied from here:
" https://vim.fandom.com/wiki/Indent_text_object
onoremap <silent>ai :<C-U>call my#misc#IndentTextObject(0)<CR>
onoremap <silent>ii :<C-U>call my#misc#IndentTextObject(1)<CR>
vnoremap <silent>ai :<C-U>call my#misc#IndentTextObject(0)<CR><Esc>gv
vnoremap <silent>ii :<C-U>call my#misc#IndentTextObject(1)<CR><Esc>gv

" pretty-simple is a Haskell tool that formats Haskell show instances, but
" handles generic stuff pretty well too.
" See: https://hackage.haskell.org/package/pretty-simple
" Install with:
" cabal install pretty-simple --flag buildexe
if executable('pretty-simple')
    nnoremap <silent> g== !!pretty-simple -c no-color<CR>
    nnoremap <silent> g= :set opfunc=my#misc#PrettySimple<CR>g@
    xnoremap <silent> g= :<C-U>call my#misc#PrettySimple(visualmode(), 1)<CR>
endif


nnoremap <Leader>ds :call my#misc#SynStack()<CR>
lua require('my.diagnostics').configure()

command GetMasterBranchLink call my#misc#get_optimistic_branch_link("master")
command GetSheetsLink call my#misc#get_filename_sheets_link()

" finally load local vim configuration if it exists
if filereadable($VIMHOME.'/local.vim')
    source $VIMHOME/local.vim
endif
