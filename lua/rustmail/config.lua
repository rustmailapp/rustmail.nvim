local M = {}

M.defaults = {
  host = "127.0.0.1",
  port = 8025,
  smtp_port = 1025,
  auto_start = false,
  binary = "rustmail",
  poll_interval = 2000,
  float = {
    width = 0.8,
    height = 0.8,
    border = "rounded",
  },
  keymaps = {
    list = {
      open = "<CR>",
      delete = "dd",
      toggle_read = "mr",
      toggle_star = "ms",
      refresh = "R",
      search = "/",
      quit = "q",
      clear_all = "D",
    },
    detail = {
      back = "<BS>",
      delete = "dd",
      toggle_read = "mr",
      toggle_star = "ms",
      quit = "q",
      view_raw = "gR",
      view_attachments = "ga",
      view_auth = "gA",
    },
  },
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

function M.base_url()
  return string.format("http://%s:%d", M.options.host, M.options.port)
end

return M
