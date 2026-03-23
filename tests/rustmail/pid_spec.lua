describe("rustmail.pid", function()
  local pid_mod
  local tmp_dir
  local original_file

  before_each(function()
    package.loaded["rustmail.pid"] = nil
    pid_mod = require("rustmail.pid")

    tmp_dir = vim.fn.tempname()
    vim.fn.mkdir(tmp_dir, "p")

    original_file = pid_mod.file
    pid_mod.file = function()
      return tmp_dir .. "/rustmail.pid"
    end
  end)

  after_each(function()
    pid_mod.file = original_file
    vim.fn.delete(tmp_dir, "rf")
  end)

  it("returns nil when no pid file exists", function()
    assert.is_nil(pid_mod.read())
  end)

  it("round-trips a valid pid", function()
    pid_mod.write(12345)
    assert.are.equal(12345, pid_mod.read())
  end)

  it("write returns true on success", function()
    assert.is_true(pid_mod.write(42))
  end)

  it("write returns false when directory does not exist", function()
    pid_mod.file = function()
      return "/nonexistent_dir_xyzzy/rustmail.pid"
    end
    assert.is_false(pid_mod.write(42))
  end)

  it("clears the pid file", function()
    pid_mod.write(99)
    pid_mod.clear()
    assert.is_nil(pid_mod.read())
  end)

  it("returns nil for empty file content", function()
    local f = io.open(pid_mod.file(), "w")
    f:write("")
    f:close()
    assert.is_nil(pid_mod.read())
  end)

  it("returns nil for non-numeric content", function()
    local f = io.open(pid_mod.file(), "w")
    f:write("abc")
    f:close()
    assert.is_nil(pid_mod.read())
  end)

  it("returns nil for zero", function()
    local f = io.open(pid_mod.file(), "w")
    f:write("0")
    f:close()
    assert.is_nil(pid_mod.read())
  end)

  it("returns nil for negative numbers", function()
    local f = io.open(pid_mod.file(), "w")
    f:write("-5")
    f:close()
    assert.is_nil(pid_mod.read())
  end)

  it("returns nil for floats", function()
    local f = io.open(pid_mod.file(), "w")
    f:write("3.7")
    f:close()
    assert.is_nil(pid_mod.read())
  end)

  it("is_alive returns false for nil pid", function()
    assert.is_false(pid_mod.is_alive(nil))
  end)

  it("is_alive returns true for current process", function()
    local my_pid = vim.fn.getpid()
    assert.is_true(pid_mod.is_alive(my_pid))
  end)

  it("is_alive returns false for a process that has exited", function()
    local job = vim.fn.jobstart({ "true" })
    local job_pid = vim.fn.jobpid(job)
    vim.fn.jobwait({ job })
    assert.is_false(pid_mod.is_alive(job_pid))
  end)

  it("write sets file permissions to 600", function()
    pid_mod.write(12345)
    local stat = vim.uv.fs_stat(pid_mod.file())
    local mode = stat.mode % 4096
    assert.are.equal(tonumber("600", 8), mode)
  end)

  it("is_rustmail returns false for nil pid", function()
    assert.is_false(pid_mod.is_rustmail(nil))
  end)

  it("is_rustmail returns false for a non-rustmail process", function()
    local job = vim.fn.jobstart({ "sleep", "10" })
    local job_pid = vim.fn.jobpid(job)
    assert.is_false(pid_mod.is_rustmail(job_pid))
    vim.fn.jobstop(job)
  end)

  it("is_rustmail returns false for a dead process", function()
    local job = vim.fn.jobstart({ "true" })
    local job_pid = vim.fn.jobpid(job)
    vim.fn.jobwait({ job })
    assert.is_false(pid_mod.is_rustmail(job_pid))
  end)
end)
