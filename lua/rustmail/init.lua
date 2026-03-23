local M = {}

local daemon_job = nil

function M.setup(opts)
  require("rustmail.config").setup(opts)
end

function M.open()
  local cfg = require("rustmail.config").options

  if cfg.auto_start then
    M.ensure_daemon()
  end

  require("rustmail.ui.list").open()
end

function M.close()
  require("rustmail.ui.list").close()
  require("rustmail.api.websocket").disconnect()
end

function M.toggle()
  local list = require("rustmail.ui.list")
  local st = list.get_state()
  if st.win and vim.api.nvim_win_is_valid(st.win) then
    M.close()
  else
    M.open()
  end
end

function M.ensure_daemon()
  if daemon_job then return end

  local cfg = require("rustmail.config").options

  local client = require("rustmail.api.client")
  client.health_check(function()
  end, function()
    daemon_job = vim.fn.jobstart({
      cfg.binary, "serve",
      "--smtp-port", tostring(cfg.smtp_port),
      "--http-port", tostring(cfg.port),
    }, {
      detach = true,
      on_exit = function()
        daemon_job = nil
      end,
    })
    vim.notify("[rustmail] started daemon on :" .. cfg.port, vim.log.levels.INFO)
  end)
end

function M.stop_daemon()
  if daemon_job then
    vim.fn.jobstop(daemon_job)
    daemon_job = nil
    vim.notify("[rustmail] daemon stopped", vim.log.levels.INFO)
  end
end

return M
