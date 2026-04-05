---@type LazySpec
return {
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFileHistory" },
    opts = function()
      local ok, git_mod = pcall(require, "diffview.vcs.adapters.git")
      if ok and git_mod and git_mod.GitAdapter and not git_mod.GitAdapter.__lfs_textconv_patched then
        local GitAdapter = git_mod.GitAdapter
        local orig_get_show_args = GitAdapter.get_show_args

        GitAdapter.get_show_args = function(self, path, rev)
          local args = orig_get_show_args(self, path, rev)
          for _, a in ipairs(args) do
            if a == "--textconv" then return args end
          end
          for i, a in ipairs(args) do
            if a == "show" then
              table.insert(args, i + 1, "--textconv")
              return args
            end
          end
          return args
        end

        GitAdapter.__lfs_textconv_patched = true
      end

      return {}
    end,
    keys = {
      {
        "<Leader>gv",
        function()
          local ok, lib = pcall(require, "diffview.lib")
          if ok and lib.get_current_view() then
            vim.cmd "DiffviewClose"
          else
            vim.cmd "DiffviewOpen"
          end
        end,
        desc = "Toggle Diffview",
      },
    },
  },
}
