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
