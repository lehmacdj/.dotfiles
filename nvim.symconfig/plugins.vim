call plug#begin($VIMHOME."/plugged")

" motion + text objects
Plug 'wellle/targets.vim'

" normal mode mappings
Plug 'tpope/vim-surround'
Plug 'tommcdo/vim-exchange'
Plug 'tpope/vim-commentary'
Plug 'junegunn/vim-easy-align'
Plug 'tpope/vim-unimpaired'

" completion
" deoplete
" if has('nvim')
"     Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
"         \| Plug 'racer-rust/vim-racer'
"         \| Plug 'Shougo/neoinclude.vim'
"         \| Plug 'zchee/deoplete-jedi'
" end
" coc
Plug 'neoclide/coc.nvim', {'branch': 'release'}
source $VIMHOME/coc-config.vim
" Edit Coc config file
" mnemonic is comp L etion because c is already taken by config
nnoremap <Leader>el :split $VIMHOME/coc-config.vim<CR>

" utility
Plug 'tpope/vim-repeat'
Plug 'editorconfig/editorconfig-vim'
Plug 'tpope/vim-sleuth'
Plug 'sheerun/vim-polyglot'

" unix
Plug 'tpope/vim-eunuch'

" fuzzy finder
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
    \| Plug 'junegunn/fzf.vim'

" git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" syntax checking
Plug 'neomake/neomake'

" jsonnet
Plug 'google/vim-jsonnet'

" vim
Plug 'tpope/vim-scriptease'

" latex
Plug 'lervag/vimtex'
let g:tex_flavor = 'latex'

" tmux
Plug 'keith/tmux.vim'
Plug 'edkolev/tmuxline.vim'

" Brewfile
Plug 'xu-cheng/brew.vim'

" markdown
Plug 'tpope/vim-markdown'

" idris
Plug 'idris-hackers/idris-vim'

" purescript
Plug 'purescript-contrib/purescript-vim'
Plug 'FrigoEU/psc-ide-vim'

" haskell
Plug 'neovimhaskell/haskell-vim'
" Plug 'parsonsmatt/intero-neovim'
Plug 'sdiehl/vim-ormolu'

" rust
Plug 'rust-lang/rust.vim'

"swift
Plug 'keith/swift.vim'

" ui
Plug 'vim-airline/vim-airline'
    \| Plug 'vim-airline/vim-airline-themes'
Plug 'ryanoasis/vim-devicons'
Plug 'frankier/neovim-colors-solarized-truecolor-only'
" Currently using this plugin because normal vim-colors-solarized doesn't
" support termguicolors
" Plug 'altercation/vim-colors-solarized'

" c#

" neuron zettelkasten / note-taking
Plug 'fiatjaf/neuron.vim'

call plug#end()

" opam plugins
if executable('opam')
    let g:opamshare = substitute(system('opam config var share'), '\n$', '', '''')

    if executable('ocamlmerlin') && has('python')
        execute "set rtp+=".g:opamshare . "/merlin/vim"
    endif

    if executable('ocp-indent')
        execute "set rtp+=" . g:opamshare . "/ocp-indent/vim"
    endif
endif
