local config = require("rustmail.config")
local client = require("rustmail.api.client")

local M = {}

local timer = nil
local listeners = {}
local last_total = nil
local last_ids = {}

function M.on(event_type, callback)
  listeners[event_type] = listeners[event_type] or {}
  table.insert(listeners[event_type], callback)
end

function M.off(event_type, callback)
  if not listeners[event_type] then return end
  for i, cb in ipairs(listeners[event_type]) do
    if cb == callback then
      table.remove(listeners[event_type], i)
      return
    end
  end
end

function M.off_all()
  listeners = {}
end

local function dispatch(event_type, data)
  local cbs = listeners[event_type] or {}
  for _, cb in ipairs(cbs) do
    cb(data)
  end
  local wildcards = listeners["*"] or {}
  for _, cb in ipairs(wildcards) do
    cb(event_type, data)
  end
end

local function build_id_set(messages)
  local set = {}
  for _, msg in ipairs(messages) do
    set[msg.id] = true
  end
  return set
end

local function poll()
  client.list_messages({ limit = 50 }, function(data)
    local messages = data.messages or {}
    local total = data.total or 0

    if last_total == nil then
      last_total = total
      last_ids = build_id_set(messages)
      return
    end

    if total ~= last_total then
      local new_ids = build_id_set(messages)

      if total == 0 and last_total > 0 then
        dispatch("messages:clear", nil)
      elseif total > last_total then
        for _, msg in ipairs(messages) do
          if not last_ids[msg.id] then
            dispatch("message:new", msg)
          end
        end
      elseif total < last_total then
        for id, _ in pairs(last_ids) do
          if not new_ids[id] then
            dispatch("message:delete", { id = id })
          end
        end
      end

      last_total = total
      last_ids = new_ids
    end
  end)
end

function M.connect()
  if timer then return end

  last_total = nil
  last_ids = {}

  timer = vim.uv.new_timer()
  timer:start(0, config.options.poll_interval, vim.schedule_wrap(poll))
end

function M.disconnect()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
  listeners = {}
  last_total = nil
  last_ids = {}
end

function M.is_connected()
  return timer ~= nil
end

return M
