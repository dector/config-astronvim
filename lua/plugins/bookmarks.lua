---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts = opts or {}
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}

      local function with_bookmarks(fn_name)
        local mod = require "utils.bookmarks"
        if type(mod[fn_name]) ~= "function" then
          package.loaded["utils.bookmarks"] = nil
          mod = require "utils.bookmarks"
        end

        if type(mod[fn_name]) ~= "function" then
          vim.notify("bookmarks: missing function " .. fn_name, vim.log.levels.ERROR)
          return
        end

        mod[fn_name]()
      end

      opts.mappings.n["<Leader>ml"] = {
        function() with_bookmarks "show_list" end,
        desc = "List bookmarks",
      }

      opts.mappings.n["<Leader>ma"] = {
        function() with_bookmarks "add_current" end,
        desc = "Add bookmark",
      }

      opts.mappings.n["<Leader>mA"] = {
        function() with_bookmarks "remove_current" end,
        desc = "Remove bookmark",
      }

      if vim.fn.exists(":BookmarkList") == 0 then
        vim.api.nvim_create_user_command("BookmarkList", function()
          with_bookmarks "show_list"
        end, { desc = "Show bookmarks" })
      end

      if vim.fn.exists(":BookmarkAdd") == 0 then
        vim.api.nvim_create_user_command("BookmarkAdd", function()
          with_bookmarks "add_current"
        end, { desc = "Add bookmark" })
      end

      if vim.fn.exists(":BookmarkRemove") == 0 then
        vim.api.nvim_create_user_command("BookmarkRemove", function()
          with_bookmarks "remove_current"
        end, { desc = "Remove bookmark" })
      end

      return opts
    end,
  },
}
