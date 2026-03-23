local config = require("rustmail.config")

local M = {}

function M.float_dims()
  local f = config.options.float
  local width = math.floor(vim.o.columns * f.width)
  local height = math.floor(vim.o.lines * f.height)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  return { width = width, height = height, col = col, row = row }
end

function M.create_scratch_buf()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
  return buf
end

function M.open_float(buf, opts)
  opts = opts or {}
  local dims = opts.dims or M.float_dims()
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = dims.width,
    height = dims.height,
    col = dims.col,
    row = dims.row,
    style = "minimal",
    border = opts.border or config.options.float.border,
    title = opts.title,
    title_pos = opts.title and "center" or nil,
  })
  return win
end

function M.open_popup(buf, opts)
  opts = opts or {}
  local lines = opts.lines or {}
  local width = opts.width or 60
  local height = math.min(#lines + 2, opts.max_height or 20)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = config.options.float.border,
    title = opts.title,
    title_pos = opts.title and "center" or nil,
  })

  local quit_key = config.options.keymaps.detail.quit
  vim.keymap.set("n", quit_key, function()
    vim.api.nvim_win_close(0, true)
  end, { buffer = buf, nowait = true, desc = "rustmail: close popup" })

  return win
end

return M
