local M = {}

local daemon_job = nil

local function pid_file()
  return vim.fn.stdpath("cache") .. "/rustmail.pid"
end

local function write_pid(pid)
  local f = io.open(pid_file(), "w")
  if f then
    f:write(tostring(pid))
    f:close()
  end
end

local function read_pid()
  local f = io.open(pid_file(), "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  local pid = tonumber(content)
  if not pid or pid ~= math.floor(pid) or pid <= 0 then
    return nil
  end
  return pid
end

local function clear_pid()
  os.remove(pid_file())
end

local function is_pid_alive(pid)
  if not pid then
    return false
  end
  local handle = io.popen("kill -0 " .. tostring(pid) .. " 2>/dev/null; echo $?")
  if not handle then
    return false
  end
  local result = handle:read("*a")
  handle:close()
  return vim.trim(result) == "0"
end

function M.setup(opts)
  require("rustmail.config").setup(opts)

  local cfg = require("rustmail.config").options
  if cfg.toggle_keymap then
    vim.keymap.set("n", cfg.toggle_keymap, function()
      M.toggle()
    end, { desc = "Toggle Rustmail TUI" })
  end
end

function M.open()
  local cfg = require("rustmail.config").options
  if cfg.auto_start then
    M.ensure_daemon(function()
      require("rustmail.terminal").open()
    end)
  else
    require("rustmail.terminal").open()
  end
end

function M.close()
  require("rustmail.terminal").close()
end

function M.toggle()
  require("rustmail.terminal").toggle()
end

function M.ensure_daemon(on_ready)
  if daemon_job then
    if on_ready then
      on_ready()
    end
    return
  end

  local stale_pid = read_pid()
  if stale_pid and not is_pid_alive(stale_pid) then
    clear_pid()
  end

  local cfg = require("rustmail.config").options

  local check = vim.fn.jobstart({
    "curl",
    "-sf",
    "--max-time",
    "3",
    "http://" .. cfg.host .. ":" .. cfg.port .. "/api/v1/messages?limit=1",
  }, {
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          if on_ready then
            on_ready()
          end
          return
        end

        daemon_job = vim.fn.jobstart({
          cfg.binary,
          "serve",
          "--smtp-port",
          tostring(cfg.smtp_port),
          "--http-port",
          tostring(cfg.port),
        }, {
          detach = true,
          on_exit = function()
            daemon_job = nil
            clear_pid()
          end,
        })

        if daemon_job > 0 then
          write_pid(vim.fn.jobpid(daemon_job))
          vim.notify("[rustmail] started daemon on :" .. cfg.port, vim.log.levels.INFO)
          vim.defer_fn(function()
            if on_ready then
              on_ready()
            end
          end, 1000)
        end
      end)
    end,
  })

  if check <= 0 and on_ready then
    on_ready()
  end
end

function M.stop_daemon()
  if daemon_job then
    vim.fn.jobstop(daemon_job)
    daemon_job = nil
    clear_pid()
    vim.notify("[rustmail] daemon stopped", vim.log.levels.INFO)
    return
  end

  local orphan_pid = read_pid()
  if orphan_pid and is_pid_alive(orphan_pid) then
    vim.fn.jobstart({ "kill", tostring(orphan_pid) }, {
      on_exit = function()
        clear_pid()
      end,
    })
    vim.notify("[rustmail] stopped orphaned daemon (pid " .. orphan_pid .. ")", vim.log.levels.INFO)
  end
end

return M
