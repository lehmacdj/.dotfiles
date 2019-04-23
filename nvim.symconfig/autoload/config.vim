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
