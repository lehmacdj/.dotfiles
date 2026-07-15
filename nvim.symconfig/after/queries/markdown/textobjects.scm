; extends

; Bullet-subtree text objects, used by al/il in
; after/ftplugin/markdown.vim via nvim-treesitter-textobjects.

; outer: the whole item including its nested sub-items (the subtree).
(list_item) @list_item.outer

; inner: just this item's own text. The list marker and task checkbox
; are siblings that precede the paragraph, and the nested child list is
; a sibling that follows it, so capturing the paragraph's inline content
; excludes marker, checkbox, and children alike.
(list_item (paragraph (inline) @list_item.inner))
