setlocal spell
setlocal tw=80

let b:markdown_trailing_space_rules = 1

" utilities for compiling to pdf
nmap <buffer> <LocalLeader>p :!pandoc --pdf-engine=xelatex % -o %:r.pdf<CR>
nmap <buffer> <LocalLeader>o :!open %:r.pdf<CR>
