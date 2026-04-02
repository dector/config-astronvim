---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["J"] = { "5j", desc = "Jump 5 lines down" },
          ["K"] = { "5k", desc = "Jump 5 lines up" },
          ["gh"] = { "<Cmd>normal! K<CR>", desc = "Run keywordprg" },
          ["<Leader>aj"] = { "J", desc = "Join line with next" },
          ["<Leader>'r"] = { "<Cmd>AstroReload<CR>", desc = "Reload AstroNvim config" },
          ["<Leader>pv"] = {
            function() vim.cmd "vsplit | terminal pi --extension npm:pi-nvim" end,
            desc = "Open Pi terminal (vertical)",
          },
          ["gp"] = { "<Cmd>PiSend<CR>", desc = "PiSend" },

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
