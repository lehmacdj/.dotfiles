silent! augroup! PodfileHighlight
augroup PodfileHighlight
    autocmd!
    " Podfile is the CocoaPods project file. It is a ruby dsl.
    autocmd BufNewFile,BufRead Podfile set filetype=ruby
    autocmd BufNewFile,BufRead Dangerfile set filetype=ruby
    " fastlane configuration files are also a ruby dsl
    autocmd BufNewFile,BufRead Fastfile set filetype=ruby
augroup END
