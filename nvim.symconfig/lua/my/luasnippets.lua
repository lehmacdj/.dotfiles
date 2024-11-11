local mod = {}

local luasnip = require('luasnip')
local s = luasnip.s
local f = luasnip.f

mod.load = function()
  -- if this gets significantly larger, we should move it to a separate file
  -- or use the loading instruction from here:
  -- https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md#lua
  luasnip.add_snippets('all', {
    s({
      trig = '@today',
      snippetType = 'autosnippet',
    }, {
      f(function() return os.date('%Y-%m-%d') end),
    }),

    s({
      trig = '@tomorrow',
      snippetType = 'autosnippet',
    }, {
      f(function() return os.date('%Y-%m-%d', os.time() + 86400) end),
    }),

    s({
      trig = '@yesterday',
      snippetType = 'autosnippet',
    }, {
      f(function() return os.date('%Y-%m-%d', os.time() - 86400) end),
    }),

    s({
      trig = '@now',
      snippetType = 'autosnippet',
    }, {
      f(function() return os.date('%H:%M') end),
    }),
  })
end

return mod
