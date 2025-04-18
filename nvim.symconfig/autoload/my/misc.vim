" toggle the color column value
let s:color_column_old = 0
function! my#misc#ToggleColorColumn() abort
  let l:tmp = &colorcolumn
  windo let &colorcolumn = s:color_column_old
  let s:color_column_old = l:tmp
endfunction

" strip all whitespace from a file
function! my#misc#StripWhitespace() abort
  if !g:do_autoformat
    return
  endif
  let l:pos = getpos('.')
  let l:_s = @/
  " vint: -ProhibitCommandRelyOnUser -ProhibitCommandWithUnintendedSideEffect
  " maktaba#buffer#Substitute is a portable substitute for substitute that is
  " a little safer than what I do below and probably would be better to use in
  " theory. I keep using this because it works:
  " https://github.com/google/vim-maktaba/blob/master/autoload/maktaba/buffer.vim#L147
  if exists('b:markdown_trailing_space_rules') && b:markdown_trailing_space_rules
    " avoid matching exactly a sequence of two spaces as this indicates a
    " newline in markdown
    silent! %substitute/\v([^ ])\s$/\1//
    silent! %substitute/\t$//
    silent! %substitute/\s\s\s\+$//
  else
    silent! %substitute/\s\+$//
  endif
  " vint: +ProhibitCommandRelyOnUser +ProhibitCommandWithUnintendedSideEffect
  let @/ = l:_s
  call setpos('.', l:pos)
endfunction

function! my#misc#CompileSpellFiles() abort
  for d in globpath(&runtimepath, 'spell/*.add', 0, 1)
      execute 'mkspell! ' . fnameescape(d)
  endfor
endfunction

" indent text objects copied from here:
" https://vim.fandom.com/wiki/Indent_text_object
" Some corresponding config to call this in init.vim
" consider replacing with the following for a more robust solution if having
" trouble:
" https://github.com/michaeljsmith/vim-indent-object
function! my#misc#IndentTextObject(inner) abort
  let curline = line('.')
  let lastline = line('$')
  let i = indent(line('.')) - &shiftwidth * (v:count1 - 1)
  let i = i < 0 ? 0 : i
  if getline('.') !~# '^\s*$'
    let p = line('.') - 1
    let nextblank = getline(p) =~# '^\s*$'
    while p > 0 && ((i == 0 && !nextblank) || (i > 0 && ((indent(p) >= i && !(nextblank && a:inner)) || (nextblank && !a:inner))))
      -
      let p = line('.') - 1
      let nextblank = getline(p) =~# '^\s*$'
    endwhile
    normal! 0V
    call cursor(curline, 0)
    let p = line('.') + 1
    let nextblank = getline(p) =~# '^\s*$'
    while p <= lastline && ((i == 0 && !nextblank) || (i > 0 && ((indent(p) >= i && !(nextblank && a:inner)) || (nextblank && !a:inner))))
      +
      let p = line('.') + 1
      let nextblank = getline(p) =~# '^\s*$'
    endwhile
    normal! $
  endif
endfunction

" Displays syntax stack under the cursor. Goes ahead and resolves links.
" https://stackoverflow.com/questions/9464844/how-to-get-group-name-of-highlighting-under-cursor-in-vim
function! my#misc#SynStack() abort
  let l:syns = synstack(line('.'), col('.'))
  call map(l:syns, {_, id -> [synIDattr(id, 'name'), synIDattr(synIDtrans(id), 'name')]})
  call map(l:syns, {_, pair -> pair[0] . (pair[0] != pair[1] ? '->' . pair[1] : '')})
  echo join(l:syns, ', ')
endfunction

" There isn't a better way to print messages that contain newlines, e.g. see:
" https://vi.stackexchange.com/questions/37660/how-can-i-echo-a-message-with-newlines-so-it-is-displayed-with-line-breaks-and-i
function! my#misc#err(msg) abort
  echohl ErrorMsg
  for line in split(a:msg, '\n')
    " for some reason tab characters don't render correctly with echom
    let l:cleaned_message = substitute(line, '	', '    ', '')
    echom l:cleaned_message
  endfor
  echohl None
endfunction

" Smart implementation of :tag that uses sources in this order:
" 1. tags if available
" 2. ripgrep search; at time of writing :Telescope grep_string. ripgrep
"    functionality is also available via <Leader>] directly bypassing lsp/tags
function! my#misc#smart_goto() abort
  try
    normal! 
  catch /E433: No tags file/
    call my#misc#err('no tag file found')
    lua require('telescope.builtin').grep_string({ prompt_title = 'no tag file; fell back to rg' })
  catch /E426: tag not found/
    " tag not found
    " we don't want to default to grep because this might be a sign that the
    " symbol actually doesn't exist; whereas if we don't have a tag file we
    " couldn't try at all
    call my#misc#err(
      \ 'tag not found: '
      \ . expand('<cword>')
      \ . ' - consider using <Leader>] for a fuzzy search')
  endtry
endfunction

" my#misc#smart_goto_select is to my#misc#smart_goto as <C-]> (:tag) is to g<C-]>
" (:tselect)
function! my#misc#smart_goto_select() abort
  try
    normal! g
  catch /E433: No tags file/
    call my#misc#err('no tag file found')
    lua require('telescope.builtin').grep_string({ prompt_title = 'no tag file; fell back to rg' })
  catch /E426: tag not found/
    " tag not found
    " we don't want to default to grep because this might be a sign that the
    " symbol actually doesn't exist; whereas if we dont' have a tag file we
    " couldn't try at all
    call my#misc#err(
      \ 'tag not found: '
      \ . expand('<cword>')
      \ . ' - consider using <Leader>] for a fuzzy search')
  endtry
endfunction

function! my#misc#PrettySimple(type, is_visual = v:false) abort
  let sel_save = &selection
  let &selection = 'inclusive'

  if a:is_visual
    echom 'a:type = visual'
    silent exe 'normal! gv!pretty-simple -c no-color'
  elseif a:type ==# 'line' " otherwise we're in operator mode
    echom 'a:type = line'
    silent exe "normal! '[V']!pretty-simple -c no-color"
  else
    echom 'a:type = standard'
    silent exe 'normal! `[v`]!pretty-simple -c no-color'
  endif

  let &selection = sel_save
endfunction

" Edit the primary syntax file if it exists, because we can assume that it is
" for a syntax that doesn't have support in vim otherwise. Otherwise edit the
" after syntax file, because that is what we want to edit to make
" modifications to the existing syntax config.
function! my#misc#EditSyntaxFile() abort
  let l:primary_syntax = $VIMHOME.'/syntax/'.&filetype.'.vim'
  let l:after_syntax = $VIMHOME.'/after/syntax/'.&filetype.'.vim'
  if filereadable(l:primary_syntax)
    execute 'split '.l:primary_syntax
  else
    execute 'split '.l:after_syntax
  endif
endfunction

" Intended to be mapped like so for filetypes that use markdown link syntax:
" xmap <buffer> <expr> p my#misc#magic_markdown_link_paste()
" Emulates the behavior of apps like slack.
function! my#misc#visual_magic_markdown_link_paste() abort
  let l:reg = get(v:, 'register', '"')
  let l:to_paste = getreg(l:reg)
  let l:pasting_link = l:to_paste =~# '^https\?:.*'
  let l:cursor_in_link = has('nvim')
        \ && v:lua.require'my.misc'.is_cursor_in_markdown_link_url()

  if l:pasting_link && !l:cursor_in_link
    return "S]%a()\<Esc>\"" . l:reg . 'PF]%'
  else
    return 'p'
  endif
endfunction

" Get a link to the current line in the github repository optimistically
" assuming it appears on the master branch
function! my#misc#get_optimistic_branch_link(branch_name) abort
  " TODO: allow passing in info about whether this was called with a prefix
  GetCommitLink
  let @+ = substitute(@+, '\v[0-9a-f]{40}', a:branch_name, '')
endfunction

" Get a =HYPERLINK formula that looks like the name of the file, and has a
" link to the current line of code
function! my#misc#get_filename_sheets_link() abort
  GetCommitLink
  let @+ = '=HYPERLINK("' . @+ . '", "' . expand('%:t:r') . '")'
endfunction

" function that returns the visual selection as a string
function! my#misc#GetVisualSelection() abort
  let [l:line_start, l:col_start] = [getpos("'<")[1], getpos("'<")[2]]
  let [l:line_end, l:col_end] = [getpos("'>")[1], getpos("'>")[2]]

  " Adjust for inclusive end position
  if l:col_end < l:col_start || l:line_start != l:line_end
    let l:col_end += 1
  endif

  " Get the lines in the visual selection
  let lines = getline(l:line_start, l:line_end)

  " If the selection is within a single line
  if l:line_start == l:line_end
    let lines = [strpart(lines[0], l:col_start - 1, l:col_end - l:col_start)]
  else
    " Adjust the first and last lines to the exact columns
    let lines[0] = strpart(lines[0], l:col_start - 1)
    let lines[-1] = strpart(lines[-1], 0, l:col_end - 1)
  endif

  return join(lines, "\n")
endfunction

" for rebinding zg to; this adds the word to the dictionary and commits the
" change so that I don't have to commit the change separately later
function! my#misc#commit_dictionary_word(visual_mode = 'not_visual') abort
  let l:is_visual = a:visual_mode !=# 'not_visual'
  if l:is_visual
    let l:word = my#misc#GetVisualSelection()
    execute 'normal! gvzg'
  else
    let l:word = expand('<cword>')
    execute 'normal! zg'
  endif
  call system(['git', '-C', $DOTFILES, 'add', 'nvim.symconfig/spell'])
  call system(['git', '-C', $DOTFILES, 'commit', '-m', 'vim dictionary: add ' . l:word])
endfunction
