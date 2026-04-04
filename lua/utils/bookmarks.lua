local M = {}

local SIGNS_NS_NAME = "project_bookmarks"
local SIGN_ICON = "󰃀"
local SIGN_HL = "BookmarkSign"

local signs_ns = nil
local setup_done = false

local DELETE_HISTORY_LIMIT = 10
local deleted_history_by_root = {}

local function uv_stat(path)
  local uv = vim.uv or vim.loop
  return uv.fs_stat(path)
end

local function ensure_sign_namespace()
  if signs_ns then return signs_ns end
  signs_ns = vim.api.nvim_create_namespace(SIGNS_NS_NAME)
  return signs_ns
end

local function apply_sign_highlight() vim.api.nvim_set_hl(0, SIGN_HL, { link = "DiagnosticHint", default = true }) end

local function get_project_root(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)
  local cwd = (vim.uv or vim.loop).cwd()
  local start = name ~= "" and vim.fs.dirname(name) or cwd

  local root = vim.fs.root(start, { ".git" })
  if root and root ~= "" then return root end

  return cwd
end

local function storage_dir() return vim.fn.stdpath "data" .. "/bookmarks" end

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

local function push_deleted_marks(root, marks)
  if type(root) ~= "string" or type(marks) ~= "table" or #marks == 0 then return end

  local history = deleted_history_by_root[root] or {}
  for i = #marks, 1, -1 do
    history[#history + 1] = vim.deepcopy(marks[i])
  end

  while #history > DELETE_HISTORY_LIMIT do
    table.remove(history, 1)
  end

  deleted_history_by_root[root] = history
end

local function pop_deleted_mark(root)
  local history = deleted_history_by_root[root]
  if not history or #history == 0 then return nil end
  return table.remove(history)
end

local function restore_mark(root, mark)
  if type(mark) ~= "table" then return false end

  local store, store_path = read_store(root)
  for _, existing in ipairs(store.items or {}) do
    local same_id = existing.id and mark.id and existing.id == mark.id
    local same_pos = existing.path == mark.path and tonumber(existing.line) == tonumber(mark.line)
    if same_id or same_pos then return false end
  end

  table.insert(store.items, mark)
  store.last_mark_id = mark.id or store.last_mark_id
  write_store(store, store_path)
  return true
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
  if abs == "" then return nil, "Current buffer has no file path" end

  local rel = vim.fs.relpath(root, abs)
  if not rel or rel == "" or vim.startswith(rel, "../") or rel == ".." then
    return nil, "Current file is outside project root"
  end

  local line = vim.api.nvim_win_get_cursor(0)[1]
  return {
    abs = abs,
    rel = rel,
    line = line,
  }
end

local function relpath_for_buf(root, bufnr)
  local abs = vim.api.nvim_buf_get_name(bufnr)
  if abs == "" then return nil end

  local rel = vim.fs.relpath(root, abs)
  if not rel or rel == "" or vim.startswith(rel, "../") or rel == ".." then return nil end

  return rel
end

function M.refresh_buf_signs(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  local ns = ensure_sign_namespace()
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  if not vim.api.nvim_buf_is_loaded(bufnr) then return end

  local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
  if buftype ~= "" then return end

  local root = get_project_root(bufnr)
  local rel = relpath_for_buf(root, bufnr)
  if not rel then return end

  local store = read_store(root)

  for _, mark in ipairs(store.items or {}) do
    if type(mark) == "table" and mark.path == rel then
      local line = tonumber(mark.line)
      if line and line >= 1 then
        vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
          sign_text = SIGN_ICON,
          sign_hl_group = SIGN_HL,
          priority = 20,
        })
      end
    end
  end
end

function M.refresh_current_buf_signs() M.refresh_buf_signs(vim.api.nvim_get_current_buf()) end

function M.setup()
  if setup_done then return end
  setup_done = true

  ensure_sign_namespace()
  apply_sign_highlight()

  local group = vim.api.nvim_create_augroup("ProjectBookmarksSigns", { clear = true })

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter", "DirChanged" }, {
    group = group,
    callback = function(args)
      local ok, mod = pcall(require, "utils.bookmarks")
      if ok and type(mod.refresh_buf_signs) == "function" then mod.refresh_buf_signs(args.buf) end
    end,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = apply_sign_highlight,
  })

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    M.refresh_buf_signs(bufnr)
  end
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
      M.refresh_current_buf_signs()
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

  M.refresh_current_buf_signs()
  vim.notify(string.format("Bookmark added: %s:%d", loc.rel, loc.line), vim.log.levels.INFO)
end

local function refresh_all_buf_signs()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then M.refresh_buf_signs(bufnr) end
  end
end

local function remove_marks(root, should_remove)
  local store, store_path = read_store(root)

  local kept, removed = {}, {}
  for _, mark in ipairs(store.items or {}) do
    if should_remove(mark) then
      removed[#removed + 1] = mark
    else
      kept[#kept + 1] = mark
    end
  end

  if #removed == 0 then return {} end

  store.items = kept
  if store.last_mark_id then
    local still_exists = false
    for _, mark in ipairs(store.items) do
      if mark.id == store.last_mark_id then
        still_exists = true
        break
      end
    end
    if not still_exists then store.last_mark_id = nil end
  end

  write_store(store, store_path)
  return removed
end

function M.remove_current()
  local root = get_project_root()
  local loc, err = current_location(root)
  if not loc then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  local removed = remove_marks(root, function(mark) return mark.path == loc.rel and tonumber(mark.line) == loc.line end)
  if #removed == 0 then return end

  push_deleted_marks(root, removed)
  M.refresh_current_buf_signs()
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
    if type(mark) == "table" and type(mark.path) == "string" then items[#items + 1] = to_picker_item(root, mark) end
  end

  table.sort(items, function(a, b)
    if a.recency ~= b.recency then return a.recency > b.recency end
    if a.exists ~= b.exists then return a.exists end
    local a_created = tonumber(a.mark.created_at) or 0
    local b_created = tonumber(b.mark.created_at) or 0
    if a_created ~= b_created then return a_created > b_created end
    if a.path ~= b.path then return a.path < b.path end
    return a.line < b.line
  end)

  return items
end

local function touch_last_used(root, picked_item)
  if type(picked_item) ~= "table" or type(picked_item.mark) ~= "table" then return end

  local store, store_path = read_store(root)
  local now = os.time()
  local changed = false

  for _, mark in ipairs(store.items or {}) do
    local same_id = mark.id and picked_item.mark.id and mark.id == picked_item.mark.id
    local same_pos = mark.path == picked_item.mark.path and tonumber(mark.line) == tonumber(picked_item.mark.line)
    if same_id or same_pos then
      mark.last_used_at = now
      store.last_mark_id = mark.id or store.last_mark_id
      changed = true
      break
    end
  end

  if changed then write_store(store, store_path) end
end

function M.show_list()
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    vim.notify("snacks.nvim is not available", vim.log.levels.ERROR)
    return
  end

  local root = get_project_root()
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
    show_empty = true,
    actions = {
      bookmark_delete = function(picker)
        local selected = picker:selected { fallback = true }
        if #selected == 0 then return end

        local removed_count = 0
        local last_removed = nil
        local deleted_marks = {}

        local removed_ids = {}
        for _, item in ipairs(selected) do
          local mark = item and item.mark
          if mark and mark.id and not removed_ids[mark.id] then
            removed_ids[mark.id] = true
            local removed = remove_marks(root, function(m) return m.id == mark.id end)
            if #removed > 0 then
              removed_count = removed_count + #removed
              last_removed = removed[#removed]
              vim.list_extend(deleted_marks, removed)
            end
          end
        end

        if removed_count == 0 then
          vim.notify("No bookmark removed", vim.log.levels.INFO)
          return
        end

        push_deleted_marks(root, deleted_marks)
        refresh_all_buf_signs()

        local updated = load_picker_items()
        picker.opts.items = updated
        picker:find { refresh = true }

        if removed_count == 1 and last_removed then
          vim.notify(
            string.format("Bookmark removed: %s:%d (undo: <C-u>)", last_removed.path, tonumber(last_removed.line) or 1),
            vim.log.levels.INFO
          )
        else
          vim.notify(string.format("Removed %d bookmarks (undo: <C-u>)", removed_count), vim.log.levels.INFO)
        end
      end,
      bookmark_undo_delete = function(picker)
        local mark = pop_deleted_mark(root)
        if not mark then
          vim.notify("No deleted bookmarks to restore", vim.log.levels.INFO)
          return
        end

        local restored = restore_mark(root, mark)
        if not restored then
          vim.notify("Bookmark already exists, nothing to restore", vim.log.levels.INFO)
          return
        end

        refresh_all_buf_signs()
        picker.opts.items = load_picker_items()
        picker:find { refresh = true }
        vim.notify(string.format("Bookmark restored: %s:%d", mark.path, tonumber(mark.line) or 1), vim.log.levels.INFO)
      end,
    },
    confirm = function(picker, item)
      if not item then
        picker:close()
        return
      end

      local path = item.file
      if not path or uv_stat(path) == nil then
        vim.notify(string.format("Bookmark file is missing: %s", item.path or "?"), vim.log.levels.WARN)
        return
      end

      touch_last_used(root, item)
      picker:close()

      vim.schedule(function()
        vim.cmd("edit " .. vim.fn.fnameescape(path))
        local line = tonumber(item.line) or 1
        local max_line = vim.api.nvim_buf_line_count(0)
        line = math.max(1, math.min(line, max_line))
        vim.api.nvim_win_set_cursor(0, { line, 0 })
        vim.cmd "normal! zz"
      end)
    end,
    win = {
      input = {
        keys = {
          ["<C-d>"] = { "bookmark_delete", mode = { "n", "i" }, desc = "Delete bookmark" },
          ["<C-u>"] = { "bookmark_undo_delete", mode = { "n", "i" }, desc = "Undo bookmark delete" },
        },
      },
      list = {
        keys = {
          ["<C-d>"] = { "bookmark_delete", mode = { "n", "x" }, desc = "Delete bookmark" },
          ["<C-u>"] = { "bookmark_undo_delete", mode = { "n", "x" }, desc = "Undo bookmark delete" },
        },
      },
      preview = { title = "Preview" },
    },
  }
end

return M
