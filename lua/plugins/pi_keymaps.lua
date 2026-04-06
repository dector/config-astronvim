local function get_changed_git_files()
  if vim.fn.executable "git" ~= 1 then
    vim.notify("git is not installed", vim.log.levels.ERROR)
    return nil
  end

  vim.fn.system "git rev-parse --is-inside-work-tree >/dev/null 2>&1"
  if vim.v.shell_error ~= 0 then
    vim.notify("Not inside a git repository", vim.log.levels.WARN)
    return nil
  end

  local unstaged = vim.fn.systemlist "git -c core.quotepath=off diff --name-only --relative --diff-filter=ACMR"
  local staged = vim.fn.systemlist "git -c core.quotepath=off diff --name-only --cached --relative --diff-filter=ACMR"
  local untracked = vim.fn.systemlist "git -c core.quotepath=off ls-files --others --exclude-standard"

  local files, seen = {}, {}
  for _, f in ipairs(vim.list_extend(vim.list_extend(unstaged, staged), untracked)) do
    if f ~= "" and not seen[f] then
      seen[f] = true
      files[#files + 1] = f
    end
  end

  if #files == 0 then
    vim.notify("No changed git files", vim.log.levels.INFO)
    return nil
  end

  return files
end

---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    opts = {
      options = {
        opt = {
          scrolloff = 10,
          relativenumber = false,
        },
      },
      mappings = {
        n = {
          ["J"] = { "5j", desc = "Jump 5 lines down" },
          ["K"] = { "5k", desc = "Jump 5 lines up" },
          ["H"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },
          ["L"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
          ["<C-S-H>"] = {
            function()
              local col = vim.api.nvim_win_get_cursor(0)[2]
              vim.api.nvim_win_set_cursor(0, { vim.fn.line "w0", col })
              vim.cmd "normal! zz"
            end,
            desc = "Cursor to first visible line (centered)",
          },
          ["<C-S-L>"] = {
            function()
              local col = vim.api.nvim_win_get_cursor(0)[2]
              vim.api.nvim_win_set_cursor(0, { vim.fn.line "w$", col })
              vim.cmd "normal! zz"
            end,
            desc = "Cursor to last visible line (centered)",
          },
          ["gh"] = { function() vim.diagnostic.open_float() end, desc = "Hover diagnostics" },
          ["]]"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
          ["[["] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },
          ["gd"] = { function() vim.lsp.buf.definition() end, desc = "Go to definition" },
          ["gD"] = { function() vim.lsp.buf.declaration() end, desc = "Go to declaration" },
          ["ge"] = {
            function()
              vim.cmd "Neotree focus reveal"
            end,
            desc = "Focus Explorer on current file",
          },
          ["U"] = { "<C-r>", desc = "Redo" },
          ["q"] = { "<Nop>", desc = "Disable macro recording on q" },
          ["Q"] = { "q", desc = "Record macro" },
          ["<Leader>aj"] = { "J", desc = "Join line with next" },
          ["<Leader>'r"] = { "<Cmd>AstroReload<CR>", desc = "Reload AstroNvim config" },

          -- disable original explorer focus key
          ["<Leader>o"] = false,

          -- disable default pi-nvim launcher mapping
          ["<Leader>p"] = false,
          ["gP"] = { "<Cmd>Pi<CR>", desc = "Pi" },
          ["gp"] = { "<Cmd>PiSend<CR>", desc = "PiSend" },

          -- swap default AstroNvim toggles for uz/uZ
          ["<Leader>uz"] = { function() require("snacks").toggle.zen():toggle() end, desc = "Toggle zen mode" },
          ["<Leader>uZ"] = { function() vim.cmd.HighlightColors "Toggle" end, desc = "Toggle color highlight" },
          ["<Leader>uL"] = false,
          ["<Leader>ul"] = {
            function()
              if vim.wo.number or vim.wo.relativenumber then
                vim.wo.number = false
                vim.wo.relativenumber = false
              else
                vim.wo.number = true
                vim.wo.relativenumber = false
              end
            end,
            desc = "Toggle line numbers",
          },
          ["<Leader>uf"] = {
            function()
              local pi_follow = require "utils.pi_follow"
              pi_follow.setup()
              pi_follow.toggle_current()
            end,
            desc = "Toggle terminal FOLLOW",
          },
          ["<Leader>ga"] = { "<Cmd>BlameColumnToggle<CR>", desc = "Toggle git blame annotations" },
          ["<Leader>gP"] = {
            function()
              local curtab = vim.api.nvim_get_current_tabpage()
              local tab_wins = vim.api.nvim_tabpage_list_wins(curtab)
              local has_preview = false
              local preview_wins = {}

              for _, win in ipairs(tab_wins) do
                local is_diff = vim.api.nvim_get_option_value("diff", { win = win })
                local buf = vim.api.nvim_win_get_buf(win)
                local name = vim.api.nvim_buf_get_name(buf)
                local is_gitsigns_preview = name:match "^gitsigns://" ~= nil

                if is_diff or is_gitsigns_preview then has_preview = true end
                if is_gitsigns_preview then table.insert(preview_wins, win) end
              end

              if has_preview then
                vim.cmd "diffoff!"
                for _, win in ipairs(preview_wins) do
                  if vim.api.nvim_win_is_valid(win) then pcall(vim.api.nvim_win_close, win, true) end
                end
              else
                require("gitsigns").diffthis()
              end
            end,
            desc = "Toggle full-file git hunk preview",
          },
          ["<Leader>gD"] = {
            function()
              if vim.fn.executable "git" ~= 1 then
                vim.notify("git is not installed", vim.log.levels.ERROR)
                return
              end

              vim.fn.system "git rev-parse --is-inside-work-tree >/dev/null 2>&1"
              if vim.v.shell_error ~= 0 then
                vim.notify("Not inside a git repository", vim.log.levels.WARN)
                return
              end

              local unstaged = vim.fn.systemlist { "git", "--no-pager", "diff", "--no-color" }
              local staged = vim.fn.systemlist { "git", "--no-pager", "diff", "--no-color", "--cached" }
              local untracked = vim.fn.systemlist { "git", "-c", "core.quotepath=off", "ls-files", "--others", "--exclude-standard" }

              if #unstaged == 0 and #staged == 0 and #untracked == 0 then
                vim.notify("No git changes", vim.log.levels.INFO)
                return
              end

              local lines = {}
              if #unstaged > 0 then
                vim.list_extend(lines, { "# Unstaged changes", "" })
                vim.list_extend(lines, unstaged)
                table.insert(lines, "")
              end

              if #staged > 0 then
                vim.list_extend(lines, { "# Staged changes", "" })
                vim.list_extend(lines, staged)
                table.insert(lines, "")
              end

              if #untracked > 0 then
                vim.list_extend(lines, { "# Untracked files", "" })
                for _, file in ipairs(untracked) do
                  table.insert(lines, "#   " .. file)
                end
              end

              vim.cmd "enew"
              local buf = vim.api.nvim_get_current_buf()
              vim.bo[buf].buftype = "nofile"
              vim.bo[buf].bufhidden = "wipe"
              vim.bo[buf].swapfile = false
              vim.bo[buf].filetype = "diff"
              vim.bo[buf].modifiable = true
              vim.api.nvim_buf_set_name(buf, "git://working-tree-diff")
              vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
              vim.bo[buf].modifiable = false
              vim.bo[buf].readonly = true
              vim.bo[buf].modified = false
            end,
            desc = "Show all git changes in one buffer",
          },

          -- same action as AstroNvim's <leader>o
          ["<Leader>q"] = {
            function()
              if vim.bo.filetype == "neo-tree" then
                vim.cmd.wincmd "p"
              else
                vim.cmd.Neotree "focus"
              end
            end,
            desc = "Toggle Explorer Focus",
          },

          -- remap find files
          ["<Leader>ff"] = false,
          ["<Leader>sf"] = { function() require("snacks").picker.git_files() end, desc = "Find git tracked files" },
          ["<Leader>sF"] = {
            function()
              require("snacks").picker.files {
                hidden = vim.tbl_get((vim.uv or vim.loop).fs_stat ".git" or {}, "type") == "directory",
              }
            end,
            desc = "Find files",
          },
          ["<Leader>fb"] = false,
          ["<Leader>sb"] = { function() require("snacks").picker.buffers() end, desc = "Find buffers" },

          -- remap find words/recent/git files
          ["<Leader>fl"] = false,
          ["<Leader>fw"] = false,
          ["<Leader>sl"] = { function() require("snacks").picker.lines() end, desc = "Search lines" },
          ["<Leader>se"] = { function() require("snacks").picker.grep_word() end, desc = "Find current word" },
          ["<Leader>sw"] = { function() require("snacks").picker.grep() end, desc = "Find words" },
          ["<Leader>st"] = { function() require("snacks").picker.todo_comments() end, desc = "Find TODOs" },
          ["<Leader>fo"] = false,
          ["<Leader>so"] = { function() require("snacks").picker.recent() end, desc = "Find old files" },
          ["<Leader>fg"] = false,
          ["<Leader>sG"] = {
            function()
              local files = get_changed_git_files()
              if not files then return end

              require("snacks").picker.pick {
                source = "grep",
                title = "Grep in changed git files",
                live = true,
                finder = function(_, ctx)
                  local search = (ctx and ctx.filter and ctx.filter.search) or ""

                  if search == "" then
                    local items = {}
                    for _, f in ipairs(files) do
                      items[#items + 1] = { file = f, text = f }
                    end
                    return items
                  end

                  if vim.fn.executable "rg" ~= 1 then
                    vim.notify("rg is not installed", vim.log.levels.ERROR)
                    return {}
                  end

                  local cmd = {
                    "rg",
                    "--color=never",
                    "--no-heading",
                    "--with-filename",
                    "--line-number",
                    "--column",
                    "--smart-case",
                    "--fixed-strings",
                    "--max-columns=500",
                    "--max-columns-preview",
                    "--",
                    search,
                  }
                  vim.list_extend(cmd, files)

                  local out = vim.fn.systemlist(cmd)
                  if vim.v.shell_error > 1 then
                    return {}
                  end

                  local items, matched = {}, {}
                  for _, line in ipairs(out) do
                    local file, lnum, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")
                    if file and lnum and col and text then
                      matched[file] = true
                      items[#items + 1] = {
                        file = file,
                        pos = { tonumber(lnum), tonumber(col) - 1 },
                        line = text,
                        text = line,
                      }
                    end
                  end

                  local unmatched = #files
                  for _ in pairs(matched) do
                    unmatched = unmatched - 1
                  end
                  if unmatched > 0 then
                    items[#items + 1] = { more = true, text = ("%d not displayed"):format(unmatched) }
                  end

                  return items
                end,
                format = function(item, picker)
                  if item.more then return { { item.text, "SnacksPickerDimmed" } } end
                  return require("snacks.picker.format").file(item, picker)
                end,
                confirm = function(picker, item)
                  if not item or item.more then return end
                  picker:norm(function()
                    picker:close()
                    vim.cmd.edit(vim.fn.fnameescape(item.file))
                    if item.pos then pcall(vim.api.nvim_win_set_cursor, 0, item.pos) end
                  end)
                end,
              }
            end,
            desc = "Search text in changed git files",
          },
          ["<Leader>sg"] = {
            function()
              local files = get_changed_git_files()
              if not files then return end

              require("snacks").picker.pick {
                source = "files",
                title = "Find changed git files",
                live = true,
                finder = function(_, ctx)
                  local search = vim.trim((ctx and ctx.filter and ctx.filter.search) or "")
                  local search_l = search:lower()

                  local items, unmatched = {}, 0
                  for _, f in ipairs(files) do
                    if search == "" or f:lower():find(search_l, 1, true) then
                      items[#items + 1] = { file = f, text = f }
                    else
                      unmatched = unmatched + 1
                    end
                  end

                  if search ~= "" and unmatched > 0 then
                    items[#items + 1] = { more = true, text = ("%d not displayed"):format(unmatched) }
                  end
                  return items
                end,
                format = function(item, picker)
                  if item.more then return { { item.text, "SnacksPickerDimmed" } } end
                  return require("snacks.picker.format").file(item, picker)
                end,
                confirm = function(picker, item)
                  if not item or item.more then return end
                  picker:norm(function()
                    picker:close()
                    vim.cmd.edit(vim.fn.fnameescape(item.file))
                  end)
                end,
              }
            end,
            desc = "Search changed git files",
          },
        },
        x = {
          ["gp"] = { ":<C-u>PiSendSelection<CR>", desc = "PiSendSelection" },
        },
      },
    },
  },
}
