" syntax highlight yaml frontmatter using hack from this thread:
" https://github.com/tpope/vim-markdown/issues/71
unlet b:current_syntax " b:current_syntax must be unset for loading syntax/yaml.vim
syntax include @Yaml syntax/yaml.vim
syntax region yamlFrontmatter start=/\%^---$/ end=/\v^%(\.{3}|\-{3})$/ keepend contains=@Yaml

" conceal wikilinks
syntax region wikiLink matchgroup=wikiLinkDelimiters start="\[\[" end="\]\]" contains=wikiLinkID oneline concealends
syntax match wikiLinkID "[A-Za-z0-9]\+|" contained containedin=wikiLink conceal
highlight link wikiLinkDelimiters Underlined
highlight link wikiLink Underlined
highlight link wikiLinkID Underlined

" conceal html comments
syntax region htmlCommentConceal matchgroup=htmlCommentConcealDelimiters start="<!--" end="-->" conceal
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

let b:current_syntax = 'markdown'
