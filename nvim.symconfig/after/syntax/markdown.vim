" syntax highlight yaml frontmatter using hack from this thread:
" https://github.com/tpope/vim-markdown/issues/71
try
  " b:current_syntax must be unset for loading syntax/yaml.vim
  unlet b:current_syntax
  syntax include @Yaml syntax/yaml.vim
  syntax region yamlFrontmatter start=/\%^---$/ end=/\v^%(\.{3}|\-{3})$/ keepend contains=@Yaml
finally
  let b:current_syntax = 'markdown'
endtry

" conceal wikilinks
syntax region wikiLink matchgroup=wikiLinkDelimiters start="\[\[" end="\]\]" contains=wikiLinkID oneline concealends
syntax match wikiLinkID "[A-Za-z0-9]\+|" contained containedin=wikiLink conceal
highlight link wikiLinkDelimiters Underlined
highlight link wikiLink Underlined
highlight link wikiLinkID Underlined

" conceal html comments (unless toggled off via yoc)
if !get(g:, 'show_markdown_comments', 0)
  syntax region htmlCommentConceal matchgroup=htmlCommentConcealDelimiters start="<!--" end="-->" conceal
endif
" god knows why but this highlight group messes up auto-completion?
" highlight link htmlCommentConceal Comment
" highlight link htmlCommentConcealDelimiters Comment

" clear groups that interfere with my custom syntax rules
" treesitter causes these to still syntax highlight properly regardless
syntax clear markdownH1
syntax clear markdownH2
syntax clear markdownH3
syntax clear markdownH4
syntax clear markdownH5
syntax clear markdownH6
syntax clear markdownId

" fix fenced code blocks inside blockquotes
" the default patterns don't handle the > prefix, causing the region to bleed
syntax region markdownBlockquoteCodeBlock matchgroup=markdownCodeDelimiter start="^>\s*\z(`\{3,\}\).*$" end="^>\s*\z1\s*$" keepend
syntax region markdownBlockquoteCodeBlock matchgroup=markdownCodeDelimiter start="^>\s*\z(\~\{3,\}\).*$" end="^>\s*\z1\s*$" keepend

" fix inline code spans to support nested backticks per CommonMark spec
" a backtick string delimiter must not be adjacent to other backticks
" e.g. ` ```code``` ` uses single backticks to wrap content with triple backticks
syntax clear markdownCode
" single backtick: not preceded or followed by another backtick
syn region markdownCode matchgroup=markdownCodeDelimiter start="`\@<!`\(`\)\@!" end="`\@<!`\(`\)\@!" keepend contains=markdownLineStart
" double backtick
syn region markdownCode matchgroup=markdownCodeDelimiter start="`\@<!``\(`\)\@!" end="`\@<!``\(`\)\@!" keepend contains=markdownLineStart
" triple backtick (inline only; fenced blocks handled by markdownCodeBlock)
" \(^\s*\)\@<! ensures we don't match at start of line (fenced block territory)
syn region markdownCode matchgroup=markdownCodeDelimiter start="\(^\s*\)\@<!`\@<!```\(`\)\@!" end="`\@<!```\(`\)\@!" keepend contains=markdownLineStart
" quadruple backtick
syn region markdownCode matchgroup=markdownCodeDelimiter start="\(^\s*\)\@<!`\@<!````\(`\)\@!" end="`\@<!````\(`\)\@!" keepend contains=markdownLineStart
" quintuple backtick (for wrapping content with 4 backticks)
syn region markdownCode matchgroup=markdownCodeDelimiter start="\(^\s*\)\@<!`\@<!`````\(`\)\@!" end="`\@<!`````\(`\)\@!" keepend contains=markdownLineStart
