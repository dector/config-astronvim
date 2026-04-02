local M = {}

M.follow_windows = {}
M.saved_winbar = {}
M.attached_terminal_bufs = {}
M._setup_done = false

local function is_terminal_window(win)
  if win == 0 then win = vim.api.nvim_get_current_win() end
  if not vim.api.nvim_win_is_valid(win) then return false end
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.bo[buf].buftype == "terminal"
end

local function follow_to_bottom(win)
  if not vim.api.nvim_win_is_valid(win) then return end
  local buf = vim.api.nvim_win_get_buf(win)
  local last = math.max(vim.api.nvim_buf_line_count(buf), 1)
  pcall(vim.api.nvim_win_set_cursor, win, { last, 0 })
end

local function set_follow_label(win, active)
  if not vim.api.nvim_win_is_valid(win) then return end

  if active then
    if M.saved_winbar[win] == nil then M.saved_winbar[win] = vim.wo[win].winbar end
    vim.wo[win].winbar = "%=%#WarningMsg#FOLLOW%*"
  else
    if M.saved_winbar[win] ~= nil then
      vim.wo[win].winbar = M.saved_winbar[win]
      M.saved_winbar[win] = nil
    end
  end
end

function M.set_follow(win, active)
  if win == 0 then win = vim.api.nvim_get_current_win() end
  if not is_terminal_window(win) then return end

  if active then
    M.follow_windows[win] = true
    follow_to_bottom(win)
  else
    M.follow_windows[win] = nil
  end

  set_follow_label(win, active)
end

function M.toggle_current()
  local win = vim.api.nvim_get_current_win()
  if not is_terminal_window(win) then
    vim.notify("FOLLOW toggle works in terminal windows only", vim.log.levels.WARN)
    return
  end
  M.set_follow(win, not M.follow_windows[win])
end

local function on_terminal_output(buf)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if M.follow_windows[win] then follow_to_bottom(win) end
  end
end

local function attach_terminal_buf(buf)
  if M.attached_terminal_bufs[buf] then return end
  if not vim.api.nvim_buf_is_valid(buf) then return end
  if vim.bo[buf].buftype ~= "terminal" then return end

  M.attached_terminal_bufs[buf] = true
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then on_terminal_output(buf) end
      end)
    end,
    on_detach = function() M.attached_terminal_bufs[buf] = nil end,
    on_reload = function() M.attached_terminal_bufs[buf] = nil end,
  })
end

function M.setup()
  if M._setup_done then return end
  M._setup_done = true

  local group = vim.api.nvim_create_augroup("PiFollowMode", { clear = true })

  vim.api.nvim_create_autocmd("TermOpen", {
    group = group,
    callback = function(args) attach_terminal_buf(args.buf) end,
  })

  -- Attach to already-open terminal buffers (e.g. after config reload)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    attach_terminal_buf(buf)
  end

  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(args)
      local win = tonumber(args.match)
      if not win then return end
      M.follow_windows[win] = nil
      M.saved_winbar[win] = nil
    end,
  })

  vim.api.nvim_create_autocmd("TermClose", {
    group = group,
    callback = function(args)
      M.attached_terminal_bufs[args.buf] = nil
      for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
        M.follow_windows[win] = nil
        set_follow_label(win, false)
      end
    end,
  })
end

return M
