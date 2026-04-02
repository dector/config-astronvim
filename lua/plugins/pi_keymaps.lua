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
        },
        x = {
          ["gp"] = { ":<C-u>PiSendSelection<CR>", desc = "PiSendSelection" },
        },
      },
    },
  },
}
