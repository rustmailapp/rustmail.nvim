local M = {}

M.defaults = {
  host = "127.0.0.1",
  port = 8025,
  smtp_port = 1025,
  auto_start = false,
  binary = "rustmail",
  layout = "float",
  float = {
    width = 0.9,
    height = 0.9,
    border = "rounded",
  },
  toggle_keymap = false,
}

M.options = vim.deepcopy(M.defaults)

local VALID_LAYOUTS = { float = true, tab = true }

local function is_loopback(host)
  if host == "localhost" or host == "::1" or host == "[::1]" then
    return true
  end
  local a, b, c, d = host:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
  if not a then
    return false
  end
  a, b, c, d = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
  return a == 127 and b <= 255 and c <= 255 and d <= 255
end

local function valid_port(val)
  return type(val) == "number" and val == math.floor(val) and val >= 1 and val <= 65535
end

function M.validate(opts)
  if opts.binary ~= nil then
    if type(opts.binary) ~= "string" or opts.binary == "" then
      vim.notify("[rustmail] binary must be a non-empty string, using default", vim.log.levels.WARN)
      opts.binary = nil
    elseif opts.binary:find("..", 1, true) then
      vim.notify("[rustmail] binary path must not contain '..', using default", vim.log.levels.WARN)
      opts.binary = nil
    elseif vim.fn.executable(opts.binary) ~= 1 then
      vim.notify(
        "[rustmail] binary '" .. opts.binary .. "' not found on PATH, will attempt to use it anyway",
        vim.log.levels.WARN
      )
    end
  end

  if opts.host ~= nil then
    if type(opts.host) ~= "string" or opts.host == "" then
      vim.notify("[rustmail] host must be a non-empty string, using default", vim.log.levels.WARN)
      opts.host = nil
    elseif not is_loopback(opts.host) then
      vim.notify("[rustmail] host '" .. opts.host .. "' is not a loopback address, using default", vim.log.levels.WARN)
      opts.host = nil
    end
  end

  if opts.port ~= nil then
    if not valid_port(opts.port) then
      vim.notify("[rustmail] port must be an integer 1-65535, using default", vim.log.levels.WARN)
      opts.port = nil
    end
  end

  if opts.smtp_port ~= nil then
    if not valid_port(opts.smtp_port) then
      vim.notify("[rustmail] smtp_port must be an integer 1-65535, using default", vim.log.levels.WARN)
      opts.smtp_port = nil
    end
  end

  if opts.layout ~= nil then
    if not VALID_LAYOUTS[opts.layout] then
      vim.notify(
        "[rustmail] layout must be 'float' or 'tab', got '" .. tostring(opts.layout) .. "', using default",
        vim.log.levels.WARN
      )
      opts.layout = nil
    end
  end

  return opts
end

function M.setup(opts)
  local validated = M.validate(vim.deepcopy(opts or {}))
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), validated)
end

return M
