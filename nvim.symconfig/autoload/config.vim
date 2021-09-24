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
