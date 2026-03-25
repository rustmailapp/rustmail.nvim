describe(":RustMail command", function()
  local calls
  local orig_notify

  before_each(function()
    calls = {}
    orig_notify = vim.notify

    package.loaded["rustmail"] = nil
    package.loaded["rustmail.config"] = nil
    package.loaded["rustmail.terminal"] = nil

    package.loaded["rustmail"] = {
      open = function()
        table.insert(calls, "open")
      end,
      close = function()
        table.insert(calls, "close")
      end,
      toggle = function()
        table.insert(calls, "toggle")
      end,
      stop_daemon = function()
        table.insert(calls, "stop_daemon")
      end,
    }

    vim.g.loaded_rustmail = nil
    dofile("plugin/rustmail.lua")
  end)

  after_each(function()
    vim.notify = orig_notify
    pcall(vim.api.nvim_del_user_command, "RustMail")
    vim.g.loaded_rustmail = nil
  end)

  it("calls open with no arguments", function()
    vim.cmd("RustMail")
    assert.are.same({ "open" }, calls)
  end)

  it("calls open with explicit 'open' argument", function()
    vim.cmd("RustMail open")
    assert.are.same({ "open" }, calls)
  end)

  it("calls close", function()
    vim.cmd("RustMail close")
    assert.are.same({ "close" }, calls)
  end)

  it("calls toggle", function()
    vim.cmd("RustMail toggle")
    assert.are.same({ "toggle" }, calls)
  end)

  it("calls stop_daemon", function()
    vim.cmd("RustMail stop")
    assert.are.same({ "stop_daemon" }, calls)
  end)

  it("notifies error for unknown subcommand", function()
    local notified = false
    vim.notify = function(msg, level)
      if level == vim.log.levels.ERROR and msg:match("unknown subcommand") then
        notified = true
      end
    end

    vim.cmd("RustMail nonsense")
    assert.is_true(notified)
  end)

  it("provides completion candidates", function()
    local completions = vim.fn.getcompletion("RustMail ", "cmdline")
    table.sort(completions)
    assert.are.same({ "close", "open", "stop", "toggle" }, completions)
  end)
end)
