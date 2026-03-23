local config = require("rustmail.config")
local client = require("rustmail.api.client")

local M = {}

local function map(buf, lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { buffer = buf, nowait = true, desc = "rustmail: " .. desc })
end

function M.attach_list(buf)
  local keys = config.options.keymaps.list
  local list = require("rustmail.ui.list")
  local detail = require("rustmail.ui.detail")

  map(buf, keys.open, function()
    local msg = list.get_selected_message()
    if msg then detail.open(msg.id) end
  end, "open message")

  map(buf, keys.delete, function()
    local msg = list.get_selected_message()
    if msg then
      client.delete_message(msg.id, function()
        list.fetch_and_redraw()
      end)
    end
  end, "delete message")

  map(buf, keys.toggle_read, function()
    local msg = list.get_selected_message()
    if msg then
      client.update_message(msg.id, { is_read = not msg.is_read }, function()
        list.fetch_and_redraw()
      end)
    end
  end, "toggle read")

  map(buf, keys.toggle_star, function()
    local msg = list.get_selected_message()
    if msg then
      client.update_message(msg.id, { is_starred = not msg.is_starred }, function()
        list.fetch_and_redraw()
      end)
    end
  end, "toggle starred")

  map(buf, keys.refresh, function()
    list.fetch_and_redraw()
  end, "refresh")

  map(buf, keys.search, function()
    vim.ui.input({ prompt = "Search: " }, function(input)
      if input and input ~= "" then
        list.search(input)
      else
        list.clear_search()
      end
    end)
  end, "search messages")

  map(buf, keys.clear_all, function()
    vim.ui.select({ "Yes", "No" }, { prompt = "Delete ALL messages?" }, function(choice)
      if choice == "Yes" then
        client.delete_all_messages(function()
          list.fetch_and_redraw()
        end)
      end
    end)
  end, "delete all messages")

  map(buf, keys.quit, function()
    list.close()
  end, "close")
end

function M.attach_detail(buf, message_id)
  local keys = config.options.keymaps.detail
  local detail = require("rustmail.ui.detail")

  map(buf, keys.back, function()
    detail.close()
  end, "back to list")

  map(buf, keys.delete, function()
    client.delete_message(message_id, function()
      detail.close()
      require("rustmail.ui.list").fetch_and_redraw()
    end)
  end, "delete message")

  map(buf, keys.toggle_read, function()
    client.get_message(message_id, function(msg)
      if msg then
        client.update_message(message_id, { is_read = not msg.is_read })
      end
    end)
  end, "toggle read")

  map(buf, keys.toggle_star, function()
    client.get_message(message_id, function(msg)
      if msg then
        client.update_message(message_id, { is_starred = not msg.is_starred })
      end
    end)
  end, "toggle starred")

  map(buf, keys.quit, function()
    detail.close()
  end, "close")

  map(buf, keys.view_raw, function()
    detail.show_raw(message_id)
  end, "view raw message")

  map(buf, keys.view_attachments, function()
    detail.show_attachments(message_id)
  end, "view attachments")

  map(buf, keys.view_auth, function()
    detail.show_auth(message_id)
  end, "view auth results")
end

return M
