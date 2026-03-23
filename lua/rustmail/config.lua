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
  toggle_keymap = "<leader>rm",
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
