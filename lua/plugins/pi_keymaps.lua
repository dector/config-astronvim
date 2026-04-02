---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    opts = {
      options = {
        opt = {
          scrolloff = 10,
        },
      },
      mappings = {
        n = {
          ["J"] = { "5j", desc = "Jump 5 lines down" },
          ["K"] = { "5k", desc = "Jump 5 lines up" },
          ["gh"] = { "<Cmd>normal! K<CR>", desc = "Run keywordprg" },
          ["]]"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
          ["[["] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },
          ["<C-]>"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
          ["<C-[>"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },
          ["gd"] = { function() vim.lsp.buf.definition() end, desc = "Go to definition" },
          ["gD"] = { function() vim.lsp.buf.declaration() end, desc = "Go to declaration" },
          ["U"] = { "<C-r>", desc = "Redo" },
          ["<Leader>aj"] = { "J", desc = "Join line with next" },
          ["<Leader>'r"] = { "<Cmd>AstroReload<CR>", desc = "Reload AstroNvim config" },

          -- disable original explorer focus key
          ["<Leader>o"] = false,

          -- disable default pi-nvim launcher mapping
          ["<Leader>p"] = false,
          ["gP"] = {
            function()
              local pi_follow = require "utils.pi_follow"
              pi_follow.setup()
              vim.cmd "vsplit | terminal pi --extension npm:pi-nvim"
              local win = vim.api.nvim_get_current_win()
              vim.schedule(function() pi_follow.set_follow(win, true) end)
            end,
            desc = "Open Pi terminal (vertical, FOLLOW)",
          },
          ["gp"] = { "<Cmd>PiSend<CR>", desc = "PiSend" },

          -- swap default AstroNvim toggles for uz/uZ
          ["<Leader>uz"] = { function() require("snacks").toggle.zen():toggle() end, desc = "Toggle zen mode" },
          ["<Leader>uZ"] = { function() vim.cmd.HighlightColors "Toggle" end, desc = "Toggle color highlight" },
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
          ["<Leader>fw"] = false,
          ["<Leader>sw"] = { function() require("snacks").picker.grep() end, desc = "Find words" },
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
