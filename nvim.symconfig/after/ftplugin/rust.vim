nnoremap <LocalLeader>r <Cmd>!RUST_BACKTRACE=1 cargo run<CR>
nnoremap <LocalLeader>t <Cmd>!RUST_BACKTRACE=1 cargo test<CR>
nnoremap <LocalLeader>m <Cmd>!cargo build<CR>
nnoremap <LocalLeader>or <Cmd>!cargo run --release<CR>

nnoremap <LocalLeader>d <Plug>(rust-def)
nnoremap <LocalLeader>k <Plug>(rust-doc)

let g:racer_experimental_completer = 1
