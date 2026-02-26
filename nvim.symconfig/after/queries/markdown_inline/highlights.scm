; extends
;
; NOTE: The wiki_link queries below require a custom build of the
; markdown_inline parser with EXTENSION_WIKI_LINK enabled.
; https://github.com/tree-sitter-grammars/tree-sitter-markdown
; To rebuild after :TSUpdate or on a new machine:
;
;   cd ~/opt/tree-sitter-markdown/tree-sitter-markdown-inline
;   EXTENSION_WIKI_LINK=1 tree-sitter generate
;   cc -shared -o parser.so -O2 -I src src/parser.c src/scanner.c
;   rm ~/.config/nvim/plugged/nvim-treesitter/parser/markdown_inline.so
;   cp parser.so ~/.config/nvim/plugged/nvim-treesitter/parser/markdown_inline.so
;
; The rm-then-cp avoids macOS code signing crashes (nvim-treesitter#8530).

; Conceal inline HTML comments
((html_tag) @comment
  (#lua-match? @comment "^<!%-%-")
  (#set! conceal "")
  (#set! priority 101))

; Wikilinks: conceal [[ and ]] brackets
(wiki_link
  ["[" "]"] @markup.link
  (#set! conceal ""))

; [[slug|title]]: conceal destination and pipe, show only title
(wiki_link
  (link_destination) @markup.link
  (link_text)
  (#set! conceal ""))

(wiki_link
  "|" @markup.link
  (#set! conceal ""))

; Style visible wiki link text
(wiki_link
  [
    (link_text)
    (link_destination)
  ] @markup.link.label)
