-- Detect filetypes for files with .sym* suffixes used by the dotfiles
-- install script (e.g., .symdot, .symconfig, .symclaude).
-- Strips the .sym* suffix and re-runs filetype detection on the
-- remaining filename. For .symdot, also prepends a dot to the
-- basename since the install script symlinks these as dotfiles.
vim.filetype.add({
  pattern = {
    [".*%.sym%w+.*"] = {
      priority = -math.huge,
      function(path, bufnr)
        local stripped = path:gsub("%.sym%w+.*$", "")
        if path:match("%.symdot") then
          local dir = stripped:match("^(.*/)") or ""
          local base = stripped:match("([^/]*)$")
          stripped = dir .. "." .. base
        end
        return vim.filetype.match({
          filename = stripped,
          buf = bufnr,
        })
      end,
    },
  },
})
