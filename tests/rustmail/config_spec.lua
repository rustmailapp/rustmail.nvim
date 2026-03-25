describe("rustmail.config", function()
  local config

  before_each(function()
    package.loaded["rustmail.config"] = nil
    config = require("rustmail.config")
  end)

  it("preserves defaults when setup called with nil", function()
    config.setup(nil)
    assert.are.same(config.defaults, config.options)
  end)

  it("preserves defaults when setup called with empty table", function()
    config.setup({})
    assert.are.same(config.defaults, config.options)
  end)

  it("overrides a single top-level option", function()
    config.setup({ port = 9999 })
    assert.are.equal(9999, config.options.port)
    assert.are.equal(config.defaults.host, config.options.host)
    assert.are.equal(config.defaults.smtp_port, config.options.smtp_port)
    assert.are.equal(config.defaults.binary, config.options.binary)
  end)

  it("deep-merges nested float config", function()
    config.setup({ float = { width = 0.5 } })
    assert.are.equal(0.5, config.options.float.width)
    assert.are.equal(config.defaults.float.height, config.options.float.height)
    assert.are.equal(config.defaults.float.border, config.options.float.border)
  end)

  it("overrides multiple options at once", function()
    config.setup({ host = "127.0.0.1", port = 3000, auto_start = true })
    assert.are.equal("127.0.0.1", config.options.host)
    assert.are.equal(3000, config.options.port)
    assert.is_true(config.options.auto_start)
  end)

  it("does not leak state between setup calls", function()
    config.setup({ port = 5555 })
    assert.are.equal(5555, config.options.port)

    config.setup({ host = "127.0.0.2" })
    assert.are.equal(config.defaults.port, config.options.port)
    assert.are.equal("127.0.0.2", config.options.host)
  end)

  it("does not mutate defaults table", function()
    local original_port = config.defaults.port
    config.setup({ port = 1111 })
    assert.are.equal(original_port, config.defaults.port)
  end)

  it("defaults toggle_keymap to false", function()
    config.setup({})
    assert.is_false(config.options.toggle_keymap)
  end)

  it("allows setting toggle_keymap to a string", function()
    config.setup({ toggle_keymap = "<leader>rm" })
    assert.are.equal("<leader>rm", config.options.toggle_keymap)
  end)
end)

describe("rustmail.config.validate", function()
  local config

  before_each(function()
    package.loaded["rustmail.config"] = nil
    config = require("rustmail.config")
  end)

  it("rejects non-loopback host", function()
    config.setup({ host = "attacker.com" })
    assert.are.equal(config.defaults.host, config.options.host)
  end)

  it("accepts localhost", function()
    config.setup({ host = "localhost" })
    assert.are.equal("localhost", config.options.host)
  end)

  it("accepts 127.x.x.x addresses", function()
    config.setup({ host = "127.0.0.1" })
    assert.are.equal("127.0.0.1", config.options.host)
    config.setup({ host = "127.1.2.3" })
    assert.are.equal("127.1.2.3", config.options.host)
  end)

  it("accepts ::1 IPv6 loopback", function()
    config.setup({ host = "::1" })
    assert.are.equal("::1", config.options.host)
    config.setup({ host = "[::1]" })
    assert.are.equal("[::1]", config.options.host)
  end)

  it("rejects empty host", function()
    config.setup({ host = "" })
    assert.are.equal(config.defaults.host, config.options.host)
  end)

  it("rejects 127.x.x.x with invalid octets", function()
    config.setup({ host = "127.999.0.1" })
    assert.are.equal(config.defaults.host, config.options.host)

    config.setup({ host = "127.0.0.256" })
    assert.are.equal(config.defaults.host, config.options.host)
  end)

  it("rejects non-127 IP addresses", function()
    config.setup({ host = "192.168.1.1" })
    assert.are.equal(config.defaults.host, config.options.host)

    config.setup({ host = "0.0.0.0" })
    assert.are.equal(config.defaults.host, config.options.host)
  end)

  it("rejects port out of range", function()
    config.setup({ port = 0 })
    assert.are.equal(config.defaults.port, config.options.port)

    config.setup({ port = 70000 })
    assert.are.equal(config.defaults.port, config.options.port)
  end)

  it("rejects non-integer port", function()
    config.setup({ port = 80.5 })
    assert.are.equal(config.defaults.port, config.options.port)
  end)

  it("accepts valid port", function()
    config.setup({ port = 9999 })
    assert.are.equal(9999, config.options.port)
  end)

  it("rejects smtp_port out of range", function()
    config.setup({ smtp_port = -1 })
    assert.are.equal(config.defaults.smtp_port, config.options.smtp_port)
  end)

  it("rejects invalid layout", function()
    config.setup({ layout = "taab" })
    assert.are.equal(config.defaults.layout, config.options.layout)
  end)

  it("accepts valid layouts", function()
    config.setup({ layout = "float" })
    assert.are.equal("float", config.options.layout)
    config.setup({ layout = "tab" })
    assert.are.equal("tab", config.options.layout)
  end)

  it("rejects binary with path traversal", function()
    config.setup({ binary = "../evil" })
    assert.are.equal(config.defaults.binary, config.options.binary)
  end)

  it("rejects empty binary", function()
    config.setup({ binary = "" })
    assert.are.equal(config.defaults.binary, config.options.binary)
  end)
end)
