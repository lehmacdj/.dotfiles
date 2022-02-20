" toggle the color column value
let s:color_column_old = 0
function! config#ToggleColorColumn()
    let l:tmp = &colorcolumn
    windo let &colorcolumn = s:color_column_old
    let s:color_column_old = l:tmp
endfunction

" strip all whitespace from a file
function! config#StripWhitespace()
    let l:pos = getpos('.')
    let l:_s = @/
    if exists('b:markdown_trailing_space_rules') && b:markdown_trailing_space_rules
    " avoid matching exactly a sequence of two spaces as this indicates a
    " newline in markdown
        silent! %substitute/\v([^ ])\s$/\1/
        silent! %substiute/\t$//
        silent! %substitute/\s\s\s\+$//
    else
        silent! %substitute/\s\+$//
    endif
    let @/ = l:_s
    call setpos('.', l:pos)
endfunction

function! config#CompileSpellFiles()
  for d in globpath(&runtimepath, "spell/*.add", 0, 1)
      execute "mkspell! " . fnameescape(d)
  endfor
endfunction

" indent text objects copied from here:
" https://vim.fandom.com/wiki/Indent_text_object
" Some corresponding config to call this in init.vim
" consider replacing with the following for a more robust solution if having
" trouble:
" https://github.com/michaeljsmith/vim-indent-object
function! config#IndentTextObject(inner)
  let curline = line(".")
  let lastline = line("$")
  let i = indent(line(".")) - &shiftwidth * (v:count1 - 1)
  let i = i < 0 ? 0 : i
  if getline(".") !~ "^\\s*$"
    let p = line(".") - 1
    let nextblank = getline(p) =~ "^\\s*$"
    while p > 0 && ((i == 0 && !nextblank) || (i > 0 && ((indent(p) >= i && !(nextblank && a:inner)) || (nextblank && !a:inner))))
      -
      let p = line(".") - 1
      let nextblank = getline(p) =~ "^\\s*$"
    endwhile
    normal! 0V
    call cursor(curline, 0)
    let p = line(".") + 1
    let nextblank = getline(p) =~ "^\\s*$"
    while p <= lastline && ((i == 0 && !nextblank) || (i > 0 && ((indent(p) >= i && !(nextblank && a:inner)) || (nextblank && !a:inner))))
      +
      let p = line(".") + 1
      let nextblank = getline(p) =~ "^\\s*$"
    endwhile
    normal! $
  endif
endfunction

" Displays buffer list, prompts for buffer numbers and ranges and deletes
" associated buffers. Example input: 2 5,9 12
" Hit Enter alone to exit.
" Source:
" https://vi.stackexchange.com/questions/14829/close-multiple-buffers-interactively
function! config#InteractiveBufDelete()
  let l:prompt = "Specify buffers to delete: "

  ls | let bufnums = input(l:prompt)
  while strlen(bufnums)
    echo "\n"
    let buflist = split(bufnums)
    for bufitem in buflist
      if match(bufitem, '^\d\+,\d\+$') >= 0
        exec ':' . bufitem . 'bd'
      elseif match(bufitem, '^\d\+$') >= 0
        exec ':bd ' . bufitem
      else
        echohl ErrorMsg | echo 'Not a number or range: ' . bufitem | echohl None
      endif
    endfor
    ls | let bufnums = input(l:prompt)
  endwhile
endfunction

" Displays syntax stack under the cursor. Goes ahead and resolves links.
" https://stackoverflow.com/questions/9464844/how-to-get-group-name-of-highlighting-under-cursor-in-vim
function! config#SynStack()
  for i1 in synstack(line("."), col("."))
    let i2 = synIDtrans(i1)
    let n1 = synIDattr(i1, "name")
    let n2 = synIDattr(i2, "name")
    echo n1 "->" n2
  endfor
endfunction

function! config#err(msg)
  echohl ErrorMsg
  echom '[config] '.a:msg
  echohl None
endfunction

" Smart implementation of :tag that uses sources in this order:
" 1. tags if available
" 2. ripgrep search; at time of writing :Telescope grep_string. ripgrep
"    functionality is also available via <Leader>] directly bypassing lsp/tags
function! config#smart_goto()
  try
    normal! 
  catch /E433: No tags file/
    call config#err("no tag file found")
    lua << EOF
    require('telescope.builtin').grep_string({
      prompt_title = 'no tag file; fell back to rg'
    })
EOF
  catch /E426: tag not found/
    " tag not found
    " we don't want to default to grep because this might be a sign that the
    " symbol actually doesn't exist; whereas if we dont' have a tag file we
    " couldn't try at all
    call config#err(
      \ "tag not found: "
      \ . expand('<cword>')
      \ . " - consider using <Leader>] for a fuzzy search")
  endtry
endfunction

" config#smart_goto_select is to config#smart_goto as <C-]> (:tag) is to g<C-]>
" (:tselect)
function! config#smart_goto_select()
  try
    normal! g
  catch /E433: No tags file/
    call config#err("no tag file found")
    lua << EOF
    require('telescope.builtin').grep_string({
      prompt_title = 'no tag file; fell back to rg'
    })
EOF
  catch /E426: tag not found/
    " tag not found
    " we don't want to default to grep because this might be a sign that the
    " symbol actually doesn't exist; whereas if we dont' have a tag file we
    " couldn't try at all
    call config#err(
      \ "tag not found: "
      \ . expand('<cword>')
      \ . " - consider using <Leader>] for a fuzzy search")
  endtry
endfunction

function! config#PrettySimple(type, ...)
  let sel_save = &selection
  let &selection = "inclusive"

  if a:0  " Invoked from Visual mode, use gv command.
    echom "a:type = visual"
    silent exe "normal! gv!pretty-simple -c no-color"
  elseif a:type == 'line'
    echom "a:type = line"
    silent exe "normal! '[V']!pretty-simple -c no-color"
  else
    echom "a:type = standard"
    silent exe "normal! `[v`]!pretty-simple -c no-color"
  endif

  let &selection = sel_save
endfunction

" Edit the primary syntax file if it exists, because we can assume that it is
" for a syntax that doesn't have support in vim otherwise. Otherwise edit the
" after syntax file, because that is what we want to edit to make
" modifications to the existing syntax config.
function! config#EditSyntaxFile()
  let l:primary_syntax = $VIMHOME.'/syntax/'.&filetype.'.vim'
  let l:after_syntax = $VIMHOME.'/after/syntax/'.&filetype.'.vim'
  if filereadable(l:primary_syntax)
    execute 'split '.l:primary_syntax
  else
    execute 'split '.l:after_syntax
  endif
endfunction
