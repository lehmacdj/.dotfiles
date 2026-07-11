local lsp = require('my.lsp')

-- vim.lsp.log.set_level(vim.log.levels.INFO)

local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, blink = pcall(require, 'blink.cmp')
if ok then
  capabilities = blink.get_lsp_capabilities(capabilities)
end

vim.lsp.config('*', {
  cmd_env = {
    -- HLS needs this env var set to not fail with inline-c. See these issues:
    -- - https://github.com/fpco/inline-c/pull/128
    -- - https://github.com/haskell/haskell-language-server/issues/3742
    __GHCIDE__ = 1
  },
  on_attach = lsp.on_attach,
  capabilities = capabilities,
  flags = {
    debounce_text_changes = 150,
  },
})

lsp.enable('kotlin_language_server', {
  on_attach = lsp.on_attach_opts { no_formatting = true },
})

lsp.enable('sourcekit', {
  on_attach = lsp.on_attach_opts { no_formatting = true },
  cmd = { vim.trim(vim.fn.system('xcrun --find sourcekit-lsp')) },
})

lsp.enable('purescriptls')

lsp.enable('wiki_language_server', {
  cmd = { 'wiki', 'language-server' },
  on_attach = function(client, bufnr)
    lsp.on_attach(client, bufnr)
    local function wiki_cmd(command)
      client:request(
        'workspace/executeCommand',
        {
          command = command,
          arguments = { vim.uri_from_bufnr(bufnr) },
        },
        nil,
        bufnr
      )
    end
    local function lsp_character(line, byte_col)
      if client.offset_encoding == 'utf-8' then return byte_col end
      return vim.str_utfindex(
        line,
        client.offset_encoding,
        byte_col,
        false
      )
    end

    local function position(row, byte_col)
      local line = vim.api.nvim_buf_get_lines(
        bufnr,
        row,
        row + 1,
        false
      )[1]
      return {
        line = row,
        character = lsp_character(line, byte_col),
      }
    end

    local function create_note(range, open_after_creation)
      client:request(
        'workspace/executeCommand',
        {
          command = 'wiki.createNoteFromSelection',
          arguments = {{
            uri = vim.uri_from_bufnr(bufnr),
            range = range,
            openAfterCreation = open_after_creation,
          }},
        },
        nil,
        bufnr
      )
    end

    local function current_word_range()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local row, cursor_byte = cursor[1] - 1, cursor[2]
      local line = vim.api.nvim_get_current_line()
      local word = vim.fn.expand('<cword>')
      local search_from = 1
      while word ~= '' do
        local start_col, end_col = line:find(word, search_from, true)
        if not start_col then break end
        local start_byte = start_col - 1
        if start_byte <= cursor_byte and cursor_byte < end_col then
          return {
            start = position(row, start_byte),
            ['end'] = position(row, end_col),
          }
        end
        search_from = end_col + 1
      end
      vim.notify('No word under cursor', vim.log.levels.WARN)
    end

    local function visual_range()
      local anchor = vim.fn.getpos('v')
      local cursor = vim.fn.getpos('.')
      local start_mark, end_mark = anchor, cursor
      if anchor[2] > cursor[2]
        or (anchor[2] == cursor[2] and anchor[3] > cursor[3])
      then
        start_mark, end_mark = cursor, anchor
      end

      local start_row, end_row = start_mark[2] - 1, end_mark[2] - 1
      if vim.fn.mode() == 'V' then
        return {
          start = position(start_row, 0),
          ['end'] = { line = end_row + 1, character = 0 },
        }
      end

      local end_line = vim.api.nvim_buf_get_lines(
        bufnr,
        end_row,
        end_row + 1,
        false
      )[1]
      local end_byte = end_mark[3] - 1
      local final_character = vim.fn.strcharpart(
        end_line:sub(end_byte + 1),
        0,
        1
      )
      return {
        start = position(start_row, start_mark[3] - 1),
        ['end'] = position(end_row, end_byte + #final_character),
      }
    end

    local function create_from_word(open_after_creation)
      local range = current_word_range()
      if range then create_note(range, open_after_creation) end
    end

    local function create_from_visual(open_after_creation)
      local range = visual_range()
      vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'nx', false)
      create_note(range, open_after_creation)
    end

    -- Define a note from the current word/selection and enter it.
    vim.keymap.set('n', '<LocalLeader>d', function()
      create_from_word(true)
    end, { buffer = bufnr, noremap = true, silent = true })
    vim.keymap.set('x', '<LocalLeader>d', function()
      create_from_visual(true)
    end, { buffer = bufnr, noremap = true, silent = true })
    -- Uppercase D performs the same extraction without entering the note.
    vim.keymap.set('n', '<LocalLeader>D', function()
      create_from_word(false)
    end, { buffer = bufnr, noremap = true, silent = true })
    vim.keymap.set('x', '<LocalLeader>D', function()
      create_from_visual(false)
    end, { buffer = bufnr, noremap = true, silent = true })
    -- Preserve the old visual <LocalLeader>n muscle memory.
    vim.keymap.set('x', '<LocalLeader>n', function()
      create_from_visual(false)
    end, { buffer = bufnr, noremap = true, silent = true })

    vim.keymap.set('n', '[d', function()
      wiki_cmd('wiki.prevDay')
    end, { buffer = bufnr, noremap = true, silent = true })
    vim.keymap.set('n', ']d', function()
      wiki_cmd('wiki.nextDay')
    end, { buffer = bufnr, noremap = true, silent = true })
    vim.keymap.set('n', '<LocalLeader>t', function()
      wiki_cmd('wiki.today')
    end, { buffer = bufnr, noremap = true, silent = true })
  end,
})

lsp.enable('hls', {
  capabilities = {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = false
      }
    }
  },
  filetypes = {'haskell', 'lhaskell', 'cabal'},
  -- HLS formatting version is old and can't use a version from the path
  -- without recompiling from source; instead use none-ls for Ormolu
  on_attach = lsp.on_attach_opts { no_formatting = true },
})

lsp.enable('lua_ls', {
  on_attach = lsp.on_attach_opts { no_formatting = true },
  root_markers = {'selene.toml'},
})
require('lazydev').setup {}

-- toml, brew install taplo
lsp.enable('taplo', {
  on_attach = lsp.on_attach_opts { no_formatting = true },
})

-- go install github.com/sqls-server/sqls@latest
-- need to setup connection strings in ~/.config/sqls/config.yml
lsp.enable('sqls')
