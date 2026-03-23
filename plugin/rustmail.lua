if vim.g.loaded_rustmail then
  return
end
vim.g.loaded_rustmail = true

vim.api.nvim_create_user_command("Rustmail", function(cmd)
  local sub = cmd.fargs[1]
  local rustmail = require("rustmail")

  if not sub or sub == "open" then
    rustmail.open()
  elseif sub == "close" then
    rustmail.close()
  elseif sub == "toggle" then
    rustmail.toggle()
  elseif sub == "stop" then
    rustmail.stop_daemon()
  else
    vim.notify("[rustmail] unknown subcommand: " .. sub, vim.log.levels.ERROR)
  end
end, {
  nargs = "?",
  complete = function()
    return { "open", "close", "toggle", "stop" }
  end,
  desc = "Rustmail email viewer",
})
