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
