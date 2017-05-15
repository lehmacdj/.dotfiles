nnoremap <LocalLeader>r :!RUST_BACKTRACE=1 cargo run<CR>
nnoremap <LocalLeader>t :!RUST_BACKTRACE=1 cargo test<CR>
nnoremap <LocalLeader>m :!cargo build<CR>
nnoremap <LocalLeader>or :!cargo run --release<CR>

nnoremap <LocalLeader>d <Plug>(rust-def)
nnoremap <LocalLeader>k <Plug>(rust-doc)

let g:racer_experimental_completer = 1
