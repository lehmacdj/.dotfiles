; extends

; Don't highlight entire frontmatter block as @keyword.directive;
; treesitter YAML injection handles the contents, and this avoids
; yellow bleed-through on delimiters and whitespace.
([
  (plus_metadata)
  (minus_metadata)
] @none
  (#set! priority 91))

; Conceal block-level HTML comments
((html_block) @comment
  (#lua-match? @comment "^<!%-%-")
  (#set! conceal "")
  (#set! conceal_lines "")
  (#set! priority 101))
