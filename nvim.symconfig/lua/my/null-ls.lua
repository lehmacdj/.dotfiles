local mod = {}

mod.setup = function()
  local null_ls = require('null-ls')
  local formatting = null_ls.builtins.formatting
  local diagnostics = null_ls.builtins.diagnostics
  local code_actions = null_ls.builtins.code_actions
  null_ls.setup {
    on_attach = require('my.lsp').on_attach,
    root_dir = function(fname)
      return require('lspconfig').util.root_pattern('.git')(fname);
    end,
    -- diagnostics_format = '#{c}: #{m}",
    sources = {
      formatting.fourmolu.with {
        command = 'ormolu',
        extra_args = { '--cabal-default-extensions', },
      },
      formatting.cabal_fmt,
      -- prettier is absurdly slow;
      -- installation: npm install -g @fsouza/prettierd
      formatting.prettierd.with {
        filetypes = {
          'javascript', 'javascriptreact',
          'typescript', 'typescriptreact',
          'vue',
          'css', 'scss', 'less',
          'graphql',
          'handlebars',
        },
      },
      diagnostics.selene,
      diagnostics.shellcheck.with {
        diagnostics_format = 'SC#{c}: #{m}',
      },
      code_actions.shellcheck,
      diagnostics.vint,
    },
  }
end

return mod
