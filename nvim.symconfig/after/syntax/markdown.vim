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

let b:current_syntax = 'markdown'
