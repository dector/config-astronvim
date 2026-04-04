local M = {}

local function uv_stat(path)
  local uv = vim.uv or vim.loop
  return uv.fs_stat(path)
end

local function get_project_root()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  local start = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()

  local root = vim.fs.root(start, { ".git" })
  if root and root ~= "" then return root end

  return vim.uv.cwd()
end

local function storage_dir()
  return vim.fn.stdpath("data") .. "/bookmarks"
end

local function project_file(root)
  local normalized = root:gsub("/", "|"):gsub("\\", "|")
  return storage_dir() .. "/" .. normalized .. ".json"
end

local function default_store(root)
  return {
    version = 1,
    project_root = root,
    last_mark_id = nil,
    items = {},
  }
end

local function read_store(root)
  local path = project_file(root)
  if vim.fn.filereadable(path) ~= 1 then return default_store(root), path end

  local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
  if not ok or type(decoded) ~= "table" then return default_store(root), path end

  decoded.version = decoded.version or 1
  decoded.project_root = decoded.project_root or root
  decoded.items = type(decoded.items) == "table" and decoded.items or {}

  return decoded, path
end

local function write_store(store, path)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local payload = vim.json.encode(store)
  vim.fn.writefile({ payload }, path)
end

local function get_git_short_hash(root)
  local cmd = "git -C " .. vim.fn.shellescape(root) .. " rev-parse --short=8 HEAD 2>/dev/null"
  local out = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then return "nogit000" end

  local commit = out:gsub("%s+", "")
  if commit == "" then return "nogit000" end
  return commit
end

local function hash_path(rel_path)
  local ok, hash = pcall(vim.fn.sha256, rel_path)
  if not ok or type(hash) ~= "string" or hash == "" then return "pathhash" end
  return hash:sub(1, 12)
end

local function build_id(rel_path, line, root)
  return string.format("bk_%s_%s_%d", hash_path(rel_path), get_git_short_hash(root), line)
end

local function current_location(root)
  local abs = vim.api.nvim_buf_get_name(0)
  if abs == "" then
    return nil, "Current buffer has no file path"
  end

  local rel = vim.fs.relpath(root, abs)
  if not rel or rel == "" then
    return nil, "Current file is outside project root"
  end

  local line = vim.api.nvim_win_get_cursor(0)[1]
  return {
    abs = abs,
    rel = rel,
    line = line,
  }
end

function M.add_current()
  local root = get_project_root()
  local loc, err = current_location(root)
  if not loc then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  local store, store_path = read_store(root)

  for _, mark in ipairs(store.items) do
    if mark.path == loc.rel and tonumber(mark.line) == loc.line then
      store.last_mark_id = mark.id
      write_store(store, store_path)
      vim.notify(string.format("Bookmark already exists: %s:%d", loc.rel, loc.line), vim.log.levels.INFO)
      return
    end
  end

  local now = os.time()
  local mark = {
    id = build_id(loc.rel, loc.line, root),
    name = "",
    path = loc.rel,
    line = loc.line,
    created_at = now,
    last_used_at = now,
  }

  table.insert(store.items, mark)
  store.last_mark_id = mark.id
  write_store(store, store_path)

  vim.notify(string.format("Bookmark added: %s:%d", loc.rel, loc.line), vim.log.levels.INFO)
end

function M.remove_current()
  local root = get_project_root()
  local loc, err = current_location(root)
  if not loc then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  local store, store_path = read_store(root)

  local removed = nil
  local kept = {}
  for _, mark in ipairs(store.items) do
    if (not removed) and mark.path == loc.rel and tonumber(mark.line) == loc.line then
      removed = mark
    else
      kept[#kept + 1] = mark
    end
  end

  if not removed then return end

  store.items = kept
  if store.last_mark_id == removed.id then store.last_mark_id = nil end
  write_store(store, store_path)

  vim.notify(string.format("Bookmark removed: %s:%d", loc.rel, loc.line), vim.log.levels.INFO)
end

local function to_picker_item(root, mark)
  local abs = root .. "/" .. mark.path
  local exists = uv_stat(abs) ~= nil
  local filename = vim.fs.basename(mark.path)

  local recency = tonumber(mark.last_used_at) or tonumber(mark.created_at) or 0

  local line = tonumber(mark.line) or 1

  return {
    mark = mark,
    file = abs,
    line = line,
    pos = { line, 0 },
    lnum = line,
    exists = exists,
    recency = recency,
    path = mark.path,
    filename = filename,
    text = string.format("%s:%d %s %s", mark.path, line, filename, exists and "" or "[missing]"),
  }
end

local function load_picker_items()
  local root = get_project_root()
  local store = read_store(root)

  local items = {}
  for _, mark in ipairs(store.items or {}) do
    if type(mark) == "table" and type(mark.path) == "string" then
      items[#items + 1] = to_picker_item(root, mark)
    end
  end

  table.sort(items, function(a, b)
    if a.exists ~= b.exists then return a.exists end
    if a.recency ~= b.recency then return a.recency > b.recency end
    local a_created = tonumber(a.mark.created_at) or 0
    local b_created = tonumber(b.mark.created_at) or 0
    if a_created ~= b_created then return a_created > b_created end
    if a.path ~= b.path then return a.path < b.path end
    return a.line < b.line
  end)

  return items
end

function M.show_list()
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    vim.notify("snacks.nvim is not available", vim.log.levels.ERROR)
    return
  end

  local items = load_picker_items()
  if #items == 0 then
    vim.notify("No bookmarks for this project", vim.log.levels.INFO)
    return
  end

  snacks.picker.pick {
    title = "Bookmarks",
    items = items,
    format = "text",
    matcher = { fuzzy = true, smartcase = true },
    preview = "file",
    focus = "input",
    confirm = "close",
    win = {
      preview = { title = "Preview" },
    },
  }
end

return M
