---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
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
