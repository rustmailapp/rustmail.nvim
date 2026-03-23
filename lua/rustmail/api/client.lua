local config = require("rustmail.config")

local M = {}

local function request(method, path, opts)
  opts = opts or {}
  local url = config.base_url() .. path
  local args = { "curl", "-s", "-S", "-X", method, "-w", "\n%{http_code}" }

  if opts.headers then
    for k, v in pairs(opts.headers) do
      table.insert(args, "-H")
      table.insert(args, k .. ": " .. v)
    end
  end

  if opts.body then
    table.insert(args, "-H")
    table.insert(args, "Content-Type: application/json")
    table.insert(args, "-d")
    table.insert(args, vim.json.encode(opts.body))
  end

  table.insert(args, url)

  local stdout_chunks = {}
  local stderr_chunks = {}

  vim.fn.jobstart(args, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stdout_chunks, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stderr_chunks, line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        local err = table.concat(stderr_chunks, "\n")
        vim.schedule(function()
          if opts.on_error then
            opts.on_error(err)
          else
            vim.notify("[rustmail] request failed: " .. err, vim.log.levels.ERROR)
          end
        end)
        return
      end

      local raw = table.concat(stdout_chunks, "\n")
      local lines = vim.split(raw, "\n")
      local status_code = tonumber(lines[#lines]) or 0
      table.remove(lines, #lines)
      local body = table.concat(lines, "\n")

      vim.schedule(function()
        if status_code >= 400 then
          local ok, decoded = pcall(vim.json.decode, body)
          local msg = (ok and decoded.error) or body
          if opts.on_error then
            opts.on_error(msg, status_code)
          else
            vim.notify("[rustmail] " .. msg, vim.log.levels.ERROR)
          end
          return
        end

        if opts.on_success then
          if body == "" or opts.raw then
            opts.on_success(body, status_code)
          else
            local ok, decoded = pcall(vim.json.decode, body)
            if ok then
              opts.on_success(decoded, status_code)
            else
              opts.on_success(body, status_code)
            end
          end
        end
      end)
    end,
  })
end

function M.list_messages(params, on_success, on_error)
  local query = {}
  if params.q then table.insert(query, "q=" .. vim.uri_encode(params.q)) end
  if params.limit then table.insert(query, "limit=" .. params.limit) end
  if params.offset then table.insert(query, "offset=" .. params.offset) end

  local path = "/api/v1/messages"
  if #query > 0 then
    path = path .. "?" .. table.concat(query, "&")
  end

  request("GET", path, { on_success = on_success, on_error = on_error })
end

function M.get_message(id, on_success, on_error)
  request("GET", "/api/v1/messages/" .. id, { on_success = on_success, on_error = on_error })
end

function M.delete_message(id, on_success, on_error)
  request("DELETE", "/api/v1/messages/" .. id, { on_success = on_success, on_error = on_error })
end

function M.delete_all_messages(on_success, on_error)
  request("DELETE", "/api/v1/messages", { on_success = on_success, on_error = on_error })
end

function M.update_message(id, updates, on_success, on_error)
  request("PATCH", "/api/v1/messages/" .. id, {
    body = updates,
    on_success = on_success,
    on_error = on_error,
  })
end

function M.get_raw_message(id, on_success, on_error)
  request("GET", "/api/v1/messages/" .. id .. "/raw", {
    raw = true,
    on_success = on_success,
    on_error = on_error,
  })
end

function M.list_attachments(id, on_success, on_error)
  request("GET", "/api/v1/messages/" .. id .. "/attachments", {
    on_success = on_success,
    on_error = on_error,
  })
end

function M.get_auth_results(id, on_success, on_error)
  request("GET", "/api/v1/messages/" .. id .. "/auth", {
    on_success = on_success,
    on_error = on_error,
  })
end

function M.health_check(on_success, on_error)
  request("GET", "/api/v1/messages?limit=0", {
    on_success = on_success,
    on_error = on_error,
  })
end

return M
