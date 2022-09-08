" this stuff defines mechanisms for writing setup code for a plugin next to
" where the plugin is defined but then only running it after the plugins have
" loaded successfully. This machinery is only intended to be used exactly once
" just after calling plug#end.
let s:deferred = []

function! config#plugins#defer#Defer(arg)
    let l:t = type(a:arg)
    if l:t == 1 || l:t == 2
        " strings and funcrefs can be immediately appended to s:deferred: we
        " know how to run them (either interpret as lua or execute funref)
        let s:deferred += [a:arg]
    elseif l:t == 3
        " arrays are produced by let-heredoc syntax, convert them to a string
        " first so they will be interpreted by lua when run
        let s:deferred += [join(a:arg, "\n") . "\n"]
    else
        call config#err(printf('Invalid argument type for Defer: %s', l:t))
    endif
endfunction

function! config#plugins#defer#RunDeferred()
    " we need to use s:action because local-variables can't store Funcrefs
    for s:action in s:deferred
        if type(s:action) == 1
            " s:action is a snippet of lua code; we call loadstring within
            " luaeval to allow s:action to be a string with potentially
            " several commands in it
            call luaeval('loadstring(_A)()', s:action)
        elseif type(s:action) == 2
            " s:action is a function reference / anonymous function
            call s:action()
        else
            throw printf('invalid type: %d', type(s:action))
        endif
    endfor
    let s:deferred = []
endfunction
