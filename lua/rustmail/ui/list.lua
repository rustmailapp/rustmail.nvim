local config = require("rustmail.config")
local client = require("rustmail.api.client")
local render = require("rustmail.ui.render")
local window = require("rustmail.ui.window")

local M = {}

local state = {
  buf = nil,
  win = nil,
  messages = {},
  total = 0,
  query = nil,
  offset = 0,
}

local ws_callbacks = {}

local function calc_col_widths(win_width)
  local fixed = 12 + 8 + 18
  local available = win_width - fixed
  local sender_w = math.floor(available * 0.35)
  local subject_w = available - sender_w
  return { sender = math.max(sender_w, 10), subject = math.max(subject_w, 15) }
end

local function redraw()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end

  local dims = window.float_dims()
  local widths = calc_col_widths(dims.width)

  local lines = {}
  local header = render.message_list_header(widths)
  table.insert(lines, header)
  table.insert(lines, string.rep("─", dims.width - 2))

  for _, msg in ipairs(state.messages) do
    table.insert(lines, render.message_list_line(msg, widths))
  end

  if #state.messages == 0 then
    table.insert(lines, "")
    table.insert(lines, "  No messages")
  end

  table.insert(lines, "")

  local status = string.format(" %d message(s)", state.total)
  if state.query then
    status = status .. string.format("  [search: %s]", state.query)
  end
  table.insert(lines, status)

  vim.api.nvim_set_option_value("modifiable", true, { buf = state.buf })
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = state.buf })
end

function M.fetch_and_redraw()
  local params = {
    limit = 50,
    offset = state.offset,
    q = state.query,
  }

  client.list_messages(params, function(data)
    state.messages = data.messages or {}
    state.total = data.total or 0
    redraw()
  end)
end

function M.get_selected_message()
  if not state.win or not vim.api.nvim_win_is_valid(state.win) then return nil end
  local cursor = vim.api.nvim_win_get_cursor(state.win)
  local row = cursor[1]
  local idx = row - 2
  if idx >= 1 and idx <= #state.messages then
    return state.messages[idx]
  end
  return nil
end

local function subscribe_events()
  local ws = require("rustmail.api.websocket")

  local function on_new() M.fetch_and_redraw() end
  local function on_delete() M.fetch_and_redraw() end
  local function on_clear() M.fetch_and_redraw() end

  ws_callbacks = { on_new = on_new, on_delete = on_delete, on_clear = on_clear }

  if not ws.is_connected() then
    ws.connect()
  end
  ws.on("message:new", on_new)
  ws.on("message:delete", on_delete)
  ws.on("messages:clear", on_clear)
end

local function unsubscribe_events()
  local ws = require("rustmail.api.websocket")
  if ws_callbacks.on_new then ws.off("message:new", ws_callbacks.on_new) end
  if ws_callbacks.on_delete then ws.off("message:delete", ws_callbacks.on_delete) end
  if ws_callbacks.on_clear then ws.off("messages:clear", ws_callbacks.on_clear) end
  ws_callbacks = {}
end

function M.open()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_set_current_win(state.win)
    M.fetch_and_redraw()
    return
  end

  state.buf = window.create_scratch_buf()
  vim.api.nvim_set_option_value("filetype", "rustmail", { buf = state.buf })

  state.win = window.open_float(state.buf, { title = " rustmail " })

  vim.api.nvim_set_option_value("cursorline", true, { win = state.win })
  vim.api.nvim_set_option_value("wrap", false, { win = state.win })

  require("rustmail.ui.keymaps").attach_list(state.buf)

  M.fetch_and_redraw()
  subscribe_events()
end

function M.close()
  unsubscribe_events()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
  state.buf = nil
end

function M.search(query)
  state.query = query
  state.offset = 0
  M.fetch_and_redraw()
end

function M.clear_search()
  state.query = nil
  state.offset = 0
  M.fetch_and_redraw()
end

function M.get_state()
  return state
end

return M
