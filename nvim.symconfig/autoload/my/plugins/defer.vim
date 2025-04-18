" this stuff defines mechanisms for writing setup code for a plugin next to
" where the plugin is defined but then only running it after the plugins have
" loaded successfully. This machinery is only intended to be used exactly once
" just after calling plug#end.
let s:deferreds = []

" This function takes two parameters
" Caller Source:
" First is the v:throwpoint from the calling location. This is necessary to
" enable better error messages. This has a small performance impact (6ms with
" my plugins.vim at time of writing; scales linearly with the number of uses
" of defer, but standard deviation was ~10ms so not very statistically
" significant), so you could also just pass a dummy string, but then the error
" reporting won't be as good.
" Example of getting the v:throwpoint to pass:
" > try | throw 'sourceloc' | catch | call my#plugins#defer#Defer(v:throwpoint, {-> echom 'Hello world'}) | endtry
" Instead of inlining this every time, you it is better to define a command
" that expands to the boilerplate in the file where you're going to use this.
"
" Action:
" Either a lua string, list of lua strings (e.g. from let=<< with trim), or
" a vimscript funcref.
function! my#plugins#defer#Defer(caller, action) abort
    let l:t = type(a:action)
    if l:t == 1 || l:t == 2
        " strings and funcrefs can be immediately appended to s:deferreds: we
        " know how to run them (either interpret as lua or execute funref)
        let s:deferreds += [{'action': a:action, 'source_loc': a:caller}]
    elseif l:t == 3
        " arrays are produced by let-heredoc syntax, convert them to a string
        " first so they will be interpreted by lua when run
        let s:deferreds += [{'action': join(a:action, "\n") . "\n", 'source_loc': a:caller}]
    else
        call my#misc#err(printf('Invalid argument type for Defer: %s', l:t))
    endif
endfunction

function! my#plugins#defer#RunDeferred() abort
    " we need to use s:deferred because local-variables can't store Funcrefs
    for s:deferred in s:deferreds
        try
            if type(s:deferred.action) == 1
                " s:action is a snippet of lua code; we call loadstring within
                " luaeval to allow s:action to be a string with potentially
                " several commands in it
                call luaeval('loadstring(_A)()', s:deferred.action)
            elseif type(s:deferred.action) == 2
                " s:action is a function reference / anonymous function
                call s:deferred.action()
            else
                call my#misc#err(printf(
                \   'invalid type at %s:\n%d',
                \   s:deferred.source_loc,
                \   type(s:deferred.action)
                \ ))
            endif
        catch
            call my#misc#err(printf('Error from %s:', s:deferred.source_loc))
            call my#misc#err(v:exception)
        endtry
    endfor
    let s:deferreds = []
endfunction
