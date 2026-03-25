local M = {}

local pid = require("rustmail.pid")
local daemon_job = nil
local daemon_ready = false
local pending_callbacks = {}
local prev_keymap = nil
local augroup = vim.api.nvim_create_augroup("rustmail", { clear = true })

function M.setup(opts)
  require("rustmail.config").setup(opts)

  vim.api.nvim_clear_autocmds({ group = augroup })

  if prev_keymap then
    pcall(vim.keymap.del, "n", prev_keymap)
    prev_keymap = nil
  end

  local cfg = require("rustmail.config").options
  if cfg.toggle_keymap then
    prev_keymap = cfg.toggle_keymap
    vim.keymap.set("n", cfg.toggle_keymap, function()
      M.toggle()
    end, { desc = "Toggle RustMail TUI" })
  end

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      M.stop_daemon()
    end,
  })
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
  if require("rustmail.terminal").is_open() then
    M.close()
  else
    M.open()
  end
end

function M.ensure_daemon(on_ready)
  if daemon_job then
    if on_ready then
      if daemon_ready then
        on_ready()
      else
        table.insert(pending_callbacks, on_ready)
      end
    end
    return
  end

  local stale_pid = pid.read()
  if stale_pid then
    if pid.is_rustmail(stale_pid) then
      vim.fn.jobstart({ "kill", tostring(stale_pid) }, {
        on_exit = function(_, code)
          vim.schedule(function()
            if code == 0 then
              pid.clear()
              M.ensure_daemon(on_ready)
            else
              vim.notify("[rustmail] failed to kill stale daemon (pid " .. stale_pid .. ")", vim.log.levels.WARN)
            end
          end)
        end,
      })
      return
    else
      if pid.is_alive(stale_pid) then
        vim.notify("[rustmail] pid " .. stale_pid .. " is not a rustmail process, ignoring", vim.log.levels.WARN)
      end
      pid.clear()
    end
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
            daemon_ready = false
            pending_callbacks = {}
            pid.clear()
          end,
        })

        if daemon_job > 0 then
          pid.write(vim.fn.jobpid(daemon_job))
          vim.notify("[rustmail] started daemon on :" .. cfg.port, vim.log.levels.INFO)
          if on_ready then
            table.insert(pending_callbacks, on_ready)
          end
          local attempts = 0
          local max_attempts = 20
          local function poll()
            attempts = attempts + 1
            vim.fn.jobstart({
              "curl",
              "-sf",
              "--max-time",
              "1",
              "http://" .. cfg.host .. ":" .. cfg.port .. "/api/v1/messages?limit=1",
            }, {
              on_exit = function(_, poll_code)
                vim.schedule(function()
                  if poll_code == 0 then
                    daemon_ready = true
                    local cbs = pending_callbacks
                    pending_callbacks = {}
                    for _, cb in ipairs(cbs) do
                      cb()
                    end
                  elseif attempts < max_attempts then
                    vim.defer_fn(poll, 250)
                  else
                    vim.notify("[rustmail] daemon failed to become ready", vim.log.levels.WARN)
                  end
                end)
              end,
            })
          end
          vim.defer_fn(poll, 250)
        else
          vim.notify("[rustmail] failed to start daemon", vim.log.levels.ERROR)
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
    daemon_ready = false
    pending_callbacks = {}
    pid.clear()
    vim.notify("[rustmail] daemon stopped", vim.log.levels.INFO)
    return
  end

  local orphan_pid = pid.read()
  if orphan_pid and pid.is_rustmail(orphan_pid) then
    vim.fn.jobstart({ "kill", tostring(orphan_pid) }, {
      on_exit = function()
        pid.clear()
      end,
    })
    vim.notify("[rustmail] stopped orphaned daemon (pid " .. orphan_pid .. ")", vim.log.levels.INFO)
  end
end

return M
