describe("rustmail.terminal._float_dims", function()
  local terminal
  local config

  before_each(function()
    package.loaded["rustmail.terminal"] = nil
    package.loaded["rustmail.config"] = nil
    config = require("rustmail.config")
    terminal = require("rustmail.terminal")
  end)

  it("computes 90% dimensions with default config", function()
    vim.o.columns = 200
    vim.o.lines = 50
    vim.o.cmdheight = 1
    config.setup({})

    local ew, eh = 200, 50 - 1 - 1
    local expected_w = math.max(1, math.floor(ew * 0.9))
    local expected_h = math.max(1, math.floor(eh * 0.9))
    local expected_col = math.floor((ew - expected_w) / 2)
    local expected_row = math.floor((eh - expected_h) / 2)

    local dims = terminal._float_dims()
    assert.are.equal(expected_w, dims.width)
    assert.are.equal(expected_h, dims.height)
    assert.are.equal(expected_col, dims.col)
    assert.are.equal(expected_row, dims.row)
  end)

  it("computes custom dimensions", function()
    vim.o.columns = 100
    vim.o.lines = 40
    vim.o.cmdheight = 1
    config.setup({ float = { width = 0.5, height = 0.5 } })

    local ew, eh = 100, 40 - 1 - 1
    local expected_w = math.max(1, math.floor(ew * 0.5))
    local expected_h = math.max(1, math.floor(eh * 0.5))
    local expected_col = math.floor((ew - expected_w) / 2)
    local expected_row = math.floor((eh - expected_h) / 2)

    local dims = terminal._float_dims()
    assert.are.equal(expected_w, dims.width)
    assert.are.equal(expected_h, dims.height)
    assert.are.equal(expected_col, dims.col)
    assert.are.equal(expected_row, dims.row)
  end)

  it("clamps to minimum 1 for tiny editor", function()
    vim.o.columns = 12
    vim.o.lines = 3
    vim.o.cmdheight = 1
    config.setup({ float = { width = 0.01, height = 0.01 } })

    local dims = terminal._float_dims()
    assert.are.equal(1, dims.width)
    assert.are.equal(1, dims.height)
    assert.is_true(dims.col >= 0)
    assert.is_true(dims.row >= 0)
  end)

  it("handles small editor dimensions", function()
    vim.o.columns = 20
    vim.o.lines = 10
    vim.o.cmdheight = 1
    config.setup({})

    local dims = terminal._float_dims()
    assert.is_true(dims.width >= 1)
    assert.is_true(dims.height >= 1)
    assert.is_true(dims.col >= 0)
    assert.is_true(dims.row >= 0)
  end)

  it("accounts for cmdheight", function()
    vim.o.columns = 100
    vim.o.lines = 50
    vim.o.cmdheight = 3
    config.setup({})

    local dims_h3 = terminal._float_dims()

    vim.o.cmdheight = 1
    local dims_h1 = terminal._float_dims()

    assert.is_true(dims_h1.height > dims_h3.height)
  end)
end)
