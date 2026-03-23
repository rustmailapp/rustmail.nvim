local M = {}

function M.file()
  return vim.fn.stdpath("cache") .. "/rustmail.pid"
end

function M.write(pid)
  local path = M.file()
  local f, err = io.open(path, "w")
  if not f then
    vim.notify("[rustmail] failed to write pid file: " .. (err or path), vim.log.levels.WARN)
    return false
  end
  f:write(tostring(pid))
  f:close()
  vim.uv.fs_chmod(path, tonumber("600", 8))
  return true
end

function M.read()
  local f = io.open(M.file(), "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  local pid = tonumber(content)
  if not pid or pid ~= math.floor(pid) or pid <= 0 then
    return nil
  end
  return pid
end

function M.clear()
  os.remove(M.file())
end

function M.is_alive(pid)
  if not pid then
    return false
  end
  local ok, ret = pcall(vim.uv.kill, pid, 0)
  return ok and ret == 0
end

function M.is_rustmail(pid)
  if not pid or not M.is_alive(pid) then
    return false
  end
  local result = vim.fn.system({ "ps", "-p", tostring(pid), "-o", "comm=" })
  if vim.v.shell_error ~= 0 then
    return false
  end
  local comm = vim.trim(result)
  local basename = comm:match("[^/]+$") or comm
  return basename == "rustmail"
end

return M
