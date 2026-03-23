local M = {}

function M.check()
  vim.health.start("rustmail.nvim")

  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim >= 0.10")
  else
    vim.health.error("Neovim >= 0.10 required", { "Update Neovim to 0.10 or later" })
  end

  local cfg = require("rustmail.config").options

  if vim.fn.executable(cfg.binary) == 1 then
    local version = vim.fn.system({ cfg.binary, "--version" })
    vim.health.ok("rustmail binary found: " .. vim.trim(version))
  else
    vim.health.error("rustmail binary not found: " .. cfg.binary, {
      "Install rustmail: https://github.com/rustmailapp/rustmail",
      "Or set binary path: require('rustmail').setup({ binary = '/path/to/rustmail' })",
    })
  end

  if cfg.auto_start then
    if vim.fn.executable("curl") == 1 then
      vim.health.ok("curl found (needed for auto_start)")
    else
      vim.health.error("curl not found (needed for auto_start)", { "Install curl or set auto_start = false" })
    end
  else
    vim.health.info("auto_start is disabled, curl not required")
  end

  if vim.fn.executable("curl") == 1 then
    local url = "http://" .. cfg.host .. ":" .. cfg.port .. "/api/v1/messages?limit=1"
    vim.fn.system({ "curl", "-sf", "--max-time", "2", url })
    if vim.v.shell_error == 0 then
      vim.health.ok("rustmail daemon reachable at " .. cfg.host .. ":" .. cfg.port)
    else
      vim.health.warn("rustmail daemon not reachable at " .. cfg.host .. ":" .. cfg.port, {
        "Start the daemon: rustmail serve",
        "Or enable auto_start: require('rustmail').setup({ auto_start = true })",
      })
    end
  else
    vim.health.info("curl not found, skipping daemon connectivity check")
  end
end

return M
