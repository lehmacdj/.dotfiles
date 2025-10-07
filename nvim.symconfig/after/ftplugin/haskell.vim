let g:haskell_enable_quantification = 1
let g:haskell_enable_pattern_synonyms = 1
let g:haskell_enable_typeroles = 1

" ormolu setup for block formatting only
let b:ormolu_disable = 1
let g:ormolu_options=['-o -XTypeApplications', '-o -XImportQualifiedPost']

xnoremap <buffer> <silent> = :<c-u>call OrmoluArg(visualmode(), 1)<CR>
nnoremap <buffer> <silent> = :set opfunc=OrmoluArg<CR>g@
" override to make the following line not get swallowed when formatting a
" paragraph
nmap <buffer> <silent> =ap =ip

function! OrmoluArg(type, ...)
  let sel_save = &selection
  let &selection = 'exclusive'

  if a:0
    silent exe 'normal! gv:call OrmoluBlock()'
  elseif a:type ==# 'line'
    silent exe 'normal! `[V`]:call OrmoluBlock()'
  else
    silent exe 'normal! `[v`]:call OrmoluBlock()'
  endif

  let &selection = sel_save
endfunction

nnoremap <buffer> <LocalLeader>o :call <SID>open_interactive(12)<CR>

" Find and open GHC simplifier output in vertical split
nnoremap <LocalLeader>vs :call OpenDumpSimpl('dump-simpl')<CR>
nnoremap <LocalLeader>vd :call OpenDumpSimpl('p.dump-simpl')<CR>

function! OpenDumpSimpl(dump_type)
    " Get the module name from the current file
    let l:module_name = s:GetModuleName()

    if l:module_name == ''
        echo 'Could not find module declaration in current file'
        return
    endif

    " Convert module name to file path pattern (e.g., Foo.Bar.Baz -> Foo/Bar/Baz)
    let l:module_path = substitute(l:module_name, '\.', '/', 'g')

    " Search for the dump file in .stack-work
    let l:dump_files = systemlist('find .stack-work -path "*/' . l:module_path . '.' . a:dump_type . '" 2>/dev/null')

    if len(l:dump_files) == 0
        echo 'No .' . a:dump_type . ' file found for module ' . l:module_name
        return
    endif

    " If multiple files found, use the most recent one
    if len(l:dump_files) > 1
        let l:dump_file = l:dump_files[0]
        for file in l:dump_files
            if getftime(file) > getftime(l:dump_file)
                let l:dump_file = file
            endif
        endfor
    else
        let l:dump_file = l:dump_files[0]
    endif

    " Open in vertical split
    execute 'vsplit ' . l:dump_file
endfunction

function! s:GetModuleName()
    " Save current position
    let l:save_pos = getpos('.')

    " Search for module declaration from the beginning of the file
    call cursor(1, 1)

    " Pattern matches: module ModuleName or module ModuleName (
    let l:pattern = '^\s*module\s\+\(\S\+\)'
    let l:line_num = search(l:pattern, 'n')

    if l:line_num == 0
        " Restore position and return empty
        call setpos('.', l:save_pos)
        return ''
    endif

    let l:line = getline(l:line_num)
    let l:matches = matchlist(l:line, l:pattern)

    " Restore position
    call setpos('.', l:save_pos)

    if len(l:matches) >= 2
        return l:matches[1]
    else
        return ''
    endif
endfunction
function! s:open_interactive(height)
  if (!exists('s:repl_buffer_id'))
    " TODO: support projects without stack.yaml by just running ghci on
    " the current file instead
    silent call s:ensure_has_stack_yaml()
    let l:terminal_command = 'stack ghci'
    let l:terminal_options = { 'cwd': fnamemodify(s:intero_stack_yaml, ':p:h') }

    let s:repl_buffer_id = s:start_buffer(l:terminal_command, l:terminal_options, a:height)

    " setup a handler to delete the buffer id when the buffer is deleted
    augroup start_buffer_Haskell
      au!
      au BufDelete <buffer> unlet s:repl_buffer_id
    augroup END
  else
    exe 'below' . a:height . ' ' . 'split'
    exe s:repl_buffer_id . 'buffer'
  endif
endfunction

" most of this logic is stolen from github.com/parsonsmatt/intero-neovim
function! s:start_buffer(command, options, height) abort
  " Starts an Intero or GHCi REPL in a split below the current buffer. Returns
  " the ID of the buffer.
  exe 'below ' . a:height . ' split'


  enew
  silent call termopen(a:command, a:options)

  silent file 'term://' . a:command
  set bufhidden=hide
  set noswapfile
  set hidden
  let l:buffer_id = bufnr('%')
  let s:intero_job_id = b:terminal_job_id

  return l:buffer_id
endfunction

function! s:ensure_has_stack_yaml() abort
  " Find stack.yaml
  if (!exists('s:intero_stack_yaml'))
    " If there's a STACK_YAML environment variable, try to interpret
    " that.
    let l:should_cd_to_current_file = empty($STACK_YAML)
    if l:should_cd_to_current_file
      " there's no stack yaml env variable, so we can just let stack
      " figure it out.  Change dir temporarily and see if stack can
      " find a config
      silent! lcd %:p:h
    endif

    " if there's an environment variable, we assume it works
    " relative to where neovim was started.
    let l:stack_path_config = systemlist('stack path --config-location')
    call filter(l:stack_path_config, "v:val =~? '^.*\.yaml'")
    if empty(l:stack_path_config)
      echomsg 'Failed to identify a stack.yaml. Does it exist?'
    else
      let s:intero_stack_yaml = l:stack_path_config[0]
    endif

    if l:should_cd_to_current_file
      silent! lcd -
    endif
  endif
endfunction
