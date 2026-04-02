" Set up keybindings for softwrapping: remap j/k/$/0 to their g-prefixed
" variants so movement follows display lines, and provide g-prefixed
" mappings for the original linewise movement.
function! my#markdown#setup_softwrap() abort
  setlocal wrap
  setlocal linebreak
  setlocal showbreak=
  setlocal colorcolumn=
  nnoremap <buffer> j gj
  xnoremap <buffer> j gj
  nnoremap <buffer> k gk
  xnoremap <buffer> k gk
  nnoremap <buffer> $ g$
  xnoremap <buffer> $ g$
  nnoremap <buffer> 0 g0
  xnoremap <buffer> 0 g0
  " leave a way to get the original mappings
  nnoremap <buffer> gj j
  xnoremap <buffer> gj j
  nnoremap <buffer> gk k
  xnoremap <buffer> gk k
  nnoremap <buffer> g$ $
  xnoremap <buffer> g$ $
  nnoremap <buffer> g0 0
  xnoremap <buffer> g0 0
endfunction
