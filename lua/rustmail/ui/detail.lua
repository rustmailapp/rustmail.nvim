local client = require("rustmail.api.client")
local render = require("rustmail.ui.render")
local window = require("rustmail.ui.window")

local M = {}

local state = {
  buf = nil,
  win = nil,
  message_id = nil,
}

function M.open(message_id)
  state.message_id = message_id

  client.get_message(message_id, function(msg)
    if not msg then return end

    state.buf = window.create_scratch_buf()
    vim.api.nvim_set_option_value("filetype", "rustmail-detail", { buf = state.buf })

    local lines = render.message_detail_lines(msg)
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = state.buf })

    state.win = window.open_float(state.buf, {
      title = " " .. (msg.subject or "(no subject)") .. " ",
    })

    vim.api.nvim_set_option_value("wrap", true, { win = state.win })

    require("rustmail.ui.keymaps").attach_detail(state.buf, message_id)

    if not msg.is_read then
      client.update_message(message_id, { is_read = true })
    end
  end)
end

function M.show_raw(message_id)
  client.get_raw_message(message_id, function(raw)
    local buf = window.create_scratch_buf()
    vim.api.nvim_set_option_value("filetype", "mail", { buf = buf })

    local lines = vim.split(raw, "\n")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

    window.open_float(buf, { title = " Raw Message " })
    local quit_key = require("rustmail.config").options.keymaps.detail.quit
    vim.keymap.set("n", quit_key, function()
      vim.api.nvim_win_close(0, true)
    end, { buffer = buf, nowait = true, desc = "rustmail: close" })
  end)
end

function M.show_attachments(message_id)
  client.list_attachments(message_id, function(attachments)
    local lines = render.attachment_lines(attachments)

    local buf = window.create_scratch_buf()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

    window.open_popup(buf, {
      lines = lines,
      width = 60,
      title = " Attachments ",
    })
  end)
end

function M.show_auth(message_id)
  client.get_auth_results(message_id, function(auth)
    local lines = render.auth_lines(auth)

    local buf = window.create_scratch_buf()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

    window.open_popup(buf, {
      lines = lines,
      width = 70,
      title = " Auth Results ",
    })
  end)
end

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
  state.buf = nil
  state.message_id = nil
end

return M
