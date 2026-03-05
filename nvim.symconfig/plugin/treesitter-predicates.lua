-- Custom treesitter predicates for toggling HTML comment
-- concealing in markdown. Used by:
--   after/queries/markdown/highlights.scm (block comments)
--   after/queries/markdown_inline/highlights.scm (inline)
-- Toggled via vim.g.show_markdown_comments in my.markdown
-- and mapped to yoc/[oc/]oc in after/ftplugin/markdown.vim

vim.treesitter.query.add_predicate(
  'md-comments-concealed?',
  function()
    return not vim.g.show_markdown_comments
  end,
  { force = true }
)

vim.treesitter.query.add_predicate(
  'not-md-comments-concealed?',
  function()
    return vim.g.show_markdown_comments == true
  end,
  { force = true }
)
