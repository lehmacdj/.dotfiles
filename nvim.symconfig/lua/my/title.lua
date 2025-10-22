local M = {}

local function segmentize(path)
  local segments = {}
  for part in path:gmatch('[^/]+') do
    table.insert(segments, part)
  end
  return segments
end

-- Build context table from current buffer
M.build_context = function()
  local filepath = vim.fn.expand('%:p')
  if filepath == '' then
    return { fallback_title_string = '%t' }
  end

  local home = os.getenv('HOME')
  local dir = vim.fn.fnamemodify(filepath, ':h')
  local filename = vim.fn.fnamemodify(filepath, ':t')
  local repo_root = vim.fs.root(filepath, {'.git', '.jj'})

  local context = {
    filepath = filepath,
    filename = filename,
    directory = dir,
    home_directory = home,
    absolute_segments = segmentize(filepath),
    repo_root = repo_root,
    repo_dir = repo_root and vim.fn.fnamemodify(repo_root, ':t') or nil,
  }

  -- Add relative path segments if in VCS
  if repo_root then
    local repo_subpath = filepath:sub(#repo_root + 2)
    context.repo_segments = segmentize(repo_subpath)
  end

  -- Add home-relative segments if applicable
  if home and filepath:sub(1, #home) == home then
    local home_subpath = filepath:sub(#home + 2)
    context.home_segments = segmentize(home_subpath)
  end

  return context
end

-- Helper to format last N segments with optional ellipsis
local function format_segments(segments, max_segments)
  if not max_segments or #segments <= max_segments then
    return table.concat(segments, '/')
  else
    local display = {'…'}
    for i = #segments - max_segments + 1, #segments do
      table.insert(display, segments[i])
    end
    return table.concat(display, '/')
  end
end

-- Default configuration function
local function title_configs(ctx)
  return {
    -- Special case for wiki
    ctx.home_segments and ctx.home_segments[4] == 'wiki' and '📝 wiki ✨',

    -- VCS just off home directory
    ctx.repo_dir and
      ctx.home_segments and
      ctx.home_segments[1] == ctx.repo_dir and
      '~/' .. ctx.repo_dir .. '▶︎' .. format_segments(ctx.repo_segments, 3),

    -- VCS repo anywhere else
    ctx.repo_dir and ctx.repo_segments and
      '…/' .. ctx.repo_dir .. '▶︎' .. format_segments(ctx.repo_segments, 3),

    -- Home-relative
    ctx.home_segments and #ctx.home_segments <= 4 and
      '~/' .. format_segments(ctx.home_segments),

    -- Absolute path if path is short enough
    #ctx.absolute_segments <= 4 and
      '/' .. format_segments(ctx.absolute_segments),

    -- Just show last 4 segments as a fallback
    format_segments(ctx.absolute_segments, 4),
  }
end

-- Main title formatting function
M.format_title = function()
  local context = M.build_context()
  if context.fallback_title_string then
    return context.fallback_title_string
  end
  for _, config in ipairs(title_configs(context)) do
    if config then
      return config
    end
  end
end

return M
