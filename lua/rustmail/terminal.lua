local M = {}

local state = {
  buf = nil,
  win = nil,
  chan = nil,
}

local function buf_valid()
  return state.buf and vim.api.nvim_buf_is_valid(state.buf)
end

local function win_valid()
  return state.win and vim.api.nvim_win_is_valid(state.win)
end

local function build_cmd()
  local cfg = require("rustmail.config").options
  return {
    cfg.binary,
    "tui",
    "--host",
    cfg.host,
    "--port",
    tostring(cfg.port),
  }
end

local function on_win_closed()
  state.win = nil
end

local function create_buf()
  if buf_valid() then
    return state.buf
  end

  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("filetype", "rustmail", { buf = state.buf })

  return state.buf
end

local function start_terminal()
  if state.chan then
    return
  end

  state.chan = vim.fn.jobstart(build_cmd(), {
    term = true,
    on_exit = function()
      state.chan = nil
      vim.schedule(function()
        if win_valid() then
          vim.api.nvim_win_close(state.win, true)
        end
        state.win = nil
        if buf_valid() then
          vim.api.nvim_buf_delete(state.buf, { force = true })
        end
        state.buf = nil
      end)
    end,
  })
end

local function float_dims()
  local cfg = require("rustmail.config").options.float
  local ew = vim.o.columns
  local eh = vim.o.lines - vim.o.cmdheight - 1

  local w = math.floor(ew * cfg.width)
  local h = math.floor(eh * cfg.height)
  local col = math.floor((ew - w) / 2)
  local row = math.floor((eh - h) / 2)

  return { width = w, height = h, col = col, row = row }
end

local function attach_win_autocmd()
  if not state.win or not vim.api.nvim_win_is_valid(state.win) then
    return
  end

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(state.win),
    once = true,
    callback = function()
      on_win_closed()
    end,
  })
end

function M.open_float(buf)
  local dims = float_dims()
  local cfg = require("rustmail.config").options.float

  state.win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = dims.width,
    height = dims.height,
    col = dims.col,
    row = dims.row,
    style = "minimal",
    border = cfg.border,
    title = " Rustmail ",
    title_pos = "center",
  })

  attach_win_autocmd()
end

function M.open_tab(buf)
  vim.cmd("tabnew")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  state.win = win

  attach_win_autocmd()
end

function M.open()
  if win_valid() then
    vim.api.nvim_set_current_win(state.win)
    vim.cmd("startinsert")
    return
  end

  local buf = create_buf()
  local layout = require("rustmail.config").options.layout

  if layout == "tab" then
    M.open_tab(buf)
  else
    M.open_float(buf)
  end

  start_terminal()
  vim.cmd("startinsert")
end

function M.close()
  if win_valid() then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
  end
end

function M.toggle()
  if win_valid() then
    M.close()
  else
    M.open()
  end
end

function M.is_open()
  return win_valid()
end

return M
