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
          ["<Leader>sf"] = {
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
          ["<Leader>sw"] = { function() require("snacks").picker.grep() end, desc = "Find words" },
          ["<Leader>st"] = { function() require("snacks").picker.todo_comments() end, desc = "Find TODOs" },
          ["<Leader>fo"] = false,
          ["<Leader>so"] = { function() require("snacks").picker.recent() end, desc = "Find old files" },
          ["<Leader>fg"] = false,
          ["<Leader>sg"] = { function() require("snacks").picker.git_files() end, desc = "Find git files" },
        },
        x = {
          ["gp"] = { ":<C-u>PiSendSelection<CR>", desc = "PiSendSelection" },
        },
      },
    },
  },
}
