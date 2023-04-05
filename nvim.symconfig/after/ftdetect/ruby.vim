silent! augroup! PodfileHighlight
augroup PodfileHighlight
    autocmd!
    " Podfile is the CocoaPods project file. It is a ruby dsl.
    autocmd BufNewFile,BufRead Podfile set filetype=ruby
augroup END
