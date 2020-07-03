" weird changes directly to plugins manifest:
" - changed neomake linters to not use stack when finding executable
"   because hlint didn't support the most recent version

let g:ormolu_command='/nix/store/q9gbpjx6mj43ramii1zl8s8jp5qirraw-ormolu-0.1.0.0/bin/ormolu'
let g:ormolu_options=["-o -XTypeApplications"]

let g:haskell_enable_quantification = 1
let g:haskell_enable_pattern_synonyms = 1

nnoremap <buffer> <LocalLeader>o :call <SID>open_interactive(12)<CR>

function! s:open_interactive(height)
    if (!exists('s:repl_buffer_id'))
        silent call s:ensure_has_stack_yaml()
        let l:terminal_command = 'stack ghci'
        let l:terminal_options = { 'cwd': fnamemodify(s:intero_stack_yaml, ':p:h') }

        let s:repl_buffer_id = s:start_buffer(l:terminal_command, l:terminal_options, a:height)
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
