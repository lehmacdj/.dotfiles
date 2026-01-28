-- NOTE: There's a parallel implementation in bin/format-path for the zsh prompt.
-- Consider unifying these implementations in the future.

local M = {}

local function segmentize(path)
  local segments = {}
  for part in path:gmatch('[^/]+') do
    table.insert(segments, part)
  end
  return segments
end

-- Parse fugitive:// URLs
-- Format: fugitive:///path/to/repo/.git//<commit_hash>/path/in/repo
local function parse_fugitive(filepath)
  local repo_git, commit, subpath = filepath:match('^fugitive://(.+/.git)//(.-)/(.+)$')
  if repo_git then
    local repo_root = repo_git:gsub('/.git$', '')
    return {
      repo_root = repo_root,
      repo_dir = vim.fn.fnamemodify(repo_root, ':t'),
      commit = commit,
      commit_short = commit:sub(1, 8),
      repo_segments = segmentize(subpath),
      directory = repo_root .. '/' .. vim.fn.fnamemodify(subpath, ':h'),
    }
  end
end

-- Build context table from current buffer
M.build_context = function()
  local filepath = vim.fn.expand('%:p')
  if filepath == '' then
    return { fallback_title_string = '%t' }
  end

  local home = os.getenv('HOME')
  local filename = vim.fn.fnamemodify(filepath, ':t')

  -- Detect protocol (fugitive://, oil://, etc.)
  local protocol = filepath:match('^(%w+)://') or 'file'

  local context = {
    filepath = filepath,
    filename = filename,
    home_directory = home,
    absolute_segments = segmentize(filepath),
    protocol = protocol,
  }

  if protocol == 'file' then
    -- Regular file paths: use vim.fs.root for VCS detection
    context.directory = vim.fn.fnamemodify(filepath, ':h')
    local repo_root = vim.fs.root(filepath, {'.git', '.jj'})
    if repo_root and repo_root ~= '.' then
      context.repo_root = repo_root
      context.repo_dir = vim.fn.fnamemodify(repo_root, ':t')
      local repo_subpath = filepath:sub(#repo_root + 2)
      context.repo_segments = segmentize(repo_subpath)
    end
  elseif protocol == 'fugitive' then
    -- Fugitive: parse repo/commit/path from URL
    local fugitive = parse_fugitive(filepath)
    if fugitive then
      context.repo_root = fugitive.repo_root
      context.repo_dir = fugitive.repo_dir
      context.repo_segments = fugitive.repo_segments
      context.commit = fugitive.commit
      context.commit_short = fugitive.commit_short
      context.directory = fugitive.directory
    end
  else
    -- Other protocols: just set directory, skip VCS detection
    context.directory = vim.fn.fnamemodify(filepath, ':h')
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

    -- Fugitive just off home directory
    ctx.protocol == 'fugitive' and ctx.repo_dir and ctx.commit_short and
      ctx.home_directory and
      ctx.repo_root == ctx.home_directory .. '/' .. ctx.repo_dir and
      '~/' .. ctx.repo_dir .. '@' .. ctx.commit_short .. '▶︎' ..
      format_segments(ctx.repo_segments, 3),

    -- Fugitive repo anywhere else
    ctx.protocol == 'fugitive' and ctx.repo_dir and ctx.commit_short and
      '…/' .. ctx.repo_dir .. '@' .. ctx.commit_short .. '▶︎' ..
      format_segments(ctx.repo_segments, 3),

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
  for _, config in ipairs(vim.tbl_filter(function(v) return v end, title_configs(context))) do
    return config
  end
end

return M
