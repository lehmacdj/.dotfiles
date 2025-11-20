local null_ls = require('null-ls')
local helpers = require('null-ls.helpers')
local formatting = null_ls.builtins.formatting
local diagnostics = null_ls.builtins.diagnostics

-- Custom ormolu formatter for Haskell
local ormolu = {
  method = null_ls.methods.FORMATTING,
  filetypes = { 'haskell' },
  generator = helpers.formatter_factory({
    command = 'ormolu',
    args = {
      '--stdin-input-file', '$FILENAME',
      '--unsafe',
      -- I essentially always use these language extensions and when not enabled
      -- e.g. when writing a new file for the first time, sometimes the .cabal
      -- file isn't updated yet, so ormolu adds extra whitespace where it
      -- shouldn't
      '--ghc-opt=-XOverloadedLabels',
      '--ghc-opt=-XTypeApplications',
      '--ghc-opt=-XOverloadedRecordDot',
    },
    to_stdin = true,
  }),
}

null_ls.setup {
  on_attach = require('my.lsp').on_attach,
  root_dir = function(fname)
    return require('lspconfig').util.root_pattern('.git')(fname);
  end,
  sources = {
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

    -- Haskell formatter (uses ormolu from PATH)
    -- HLS uses an old version so we use this instead
    ormolu,

    -- diagnostics.selene,
    require("none-ls-shellcheck.diagnostics").with {
      diagnostics_format = 'SC#{c}: #{m}',
    },
    require("none-ls-shellcheck.code_actions"),
    diagnostics.vint,
  },
}
