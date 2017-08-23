" toggle the color column value
let s:color_column_old = 0
function! config#ToggleColorColumn()
    let l:tmp = &colorcolumn
    windo let &colorcolumn = s:color_column_old
    let s:color_column_old = l:tmp
endfunction
