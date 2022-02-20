" syntax highlight yaml frontmatter using hack from this thread:
" https://github.com/tpope/vim-markdown/issues/71
unlet b:current_syntax " b:current_syntax must be unset for loading syntax/yaml.vim
syntax include @Yaml syntax/yaml.vim
syntax region yamlFrontmatter start=/\%^---$/ end=/\v^%(\.{3}|\-{3})$/ keepend contains=@Yaml
let b:current_syntax = 'markdown'
