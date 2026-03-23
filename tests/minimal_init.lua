local PLENARY_TAG = "v0.1.4"

local plenary_path = os.getenv("PLENARY_PATH")
if not plenary_path then
  local home = os.getenv("HOME") or os.getenv("USERPROFILE")
  plenary_path = home .. "/.local/share/nvim/lazy/plenary.nvim"
end

if vim.fn.isdirectory(plenary_path) == 0 then
  plenary_path = vim.fn.stdpath("data") .. "/plenary.nvim"
  if vim.fn.isdirectory(plenary_path) == 0 then
    vim.fn.system({
      "git",
      "clone",
      "--depth",
      "1",
      "--branch",
      PLENARY_TAG,
      "https://github.com/nvim-lua/plenary.nvim",
      plenary_path,
    })
  end
end

vim.opt.rtp:prepend(plenary_path)
vim.opt.rtp:prepend(vim.fn.getcwd())
