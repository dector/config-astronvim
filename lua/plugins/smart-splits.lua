---@type LazySpec
return {
  {
    "mrjones2014/smart-splits.nvim",
    init = function() vim.g.smart_splits_multiplexer_integration = false end,
    opts = {
      at_edge = "stop",
      multiplexer_integration = false,
    },
  },
}
