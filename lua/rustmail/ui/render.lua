local M = {}

local icons = {
  read = " ",
  unread = "●",
  starred = "★",
  unstarred = " ",
  attachment = "📎",
  no_attachment = " ",
}

function M.format_size(bytes)
  if bytes < 1024 then return string.format("%dB", bytes) end
  if bytes < 1024 * 1024 then return string.format("%.1fK", bytes / 1024) end
  return string.format("%.1fM", bytes / (1024 * 1024))
end

function M.format_date(iso_str)
  if not iso_str then return "" end
  local y, mo, d, h, mi = iso_str:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+)")
  if not y then return iso_str end
  return string.format("%s-%s-%s %s:%s", y, mo, d, h, mi)
end

local function display_width(str)
  if not str or str == "" then return 0 end
  return vim.api.nvim_strwidth(str)
end

function M.truncate(str, max_cells)
  if not str then return "" end
  if display_width(str) <= max_cells then return str end

  local char_count = vim.fn.strchars(str)
  local truncated = ""
  for i = 0, char_count - 1 do
    local char = vim.fn.strcharpart(str, i, 1)
    local candidate = truncated .. char
    if display_width(candidate) > max_cells - 1 then
      break
    end
    truncated = candidate
  end
  return truncated .. "…"
end

local function pad_right(str, target_cells)
  local w = display_width(str)
  if w >= target_cells then return str end
  return str .. string.rep(" ", target_cells - w)
end

function M.parse_sender(sender)
  if not sender then return "" end
  local name = sender:match("^(.-)%s*<")
  if name and name ~= "" then return name end
  return sender:match("<(.-)>") or sender
end

function M.message_list_line(msg, widths)
  widths = widths or { sender = 20, subject = 40 }

  local read_icon = msg.is_read and icons.read or icons.unread
  local star_icon = msg.is_starred and icons.starred or icons.unstarred
  local attach_icon = msg.has_attachments and icons.attachment or icons.no_attachment

  local sender = pad_right(M.truncate(M.parse_sender(msg.sender), widths.sender), widths.sender)
  local subject = pad_right(M.truncate(msg.subject or "(no subject)", widths.subject), widths.subject)
  local size = string.format("%6s", M.format_size(msg.size))
  local date = M.format_date(msg.created_at)

  return string.format(
    " %s %s %s %s  %s  %s  %s",
    read_icon, star_icon, attach_icon, sender, subject, size, date
  )
end

function M.message_list_header(widths)
  widths = widths or { sender = 20, subject = 40 }
  local from = pad_right("From", widths.sender)
  local subj = pad_right("Subject", widths.subject)
  return string.format("       %s  %s  %6s  %s", from, subj, "Size", "Date")
end

function M.message_detail_lines(msg)
  local lines = {}

  table.insert(lines, "From:    " .. (msg.sender or ""))
  table.insert(lines, "To:      " .. M.format_recipients(msg.recipients))
  table.insert(lines, "Subject: " .. (msg.subject or "(no subject)"))
  table.insert(lines, "Date:    " .. M.format_date(msg.created_at))
  table.insert(lines, "Size:    " .. M.format_size(msg.size))

  if msg.tags and #msg.tags > 0 then
    table.insert(lines, "Tags:    " .. table.concat(msg.tags, ", "))
  end

  local status = {}
  if msg.is_read then table.insert(status, "read") else table.insert(status, "unread") end
  if msg.is_starred then table.insert(status, "starred") end
  if msg.has_attachments then table.insert(status, "has attachments") end
  table.insert(lines, "Status:  " .. table.concat(status, ", "))

  table.insert(lines, "")
  table.insert(lines, string.rep("─", 72))
  table.insert(lines, "")

  local body = msg.text_body or msg.html_body or "(no body)"
  for line in body:gmatch("[^\n]*") do
    table.insert(lines, line)
  end

  return lines
end

function M.format_recipients(recipients_str)
  if not recipients_str then return "" end
  local ok, list = pcall(vim.json.decode, recipients_str)
  if ok and type(list) == "table" then
    return table.concat(list, ", ")
  end
  return recipients_str
end

function M.attachment_lines(attachments)
  local lines = { "Attachments:", "" }
  if not attachments or #attachments == 0 then
    table.insert(lines, "  (none)")
    return lines
  end
  for i, att in ipairs(attachments) do
    local name = att.filename or "(unnamed)"
    local ctype = att.content_type or "unknown"
    local size = att.size and M.format_size(att.size) or "?"
    table.insert(lines, string.format("  %d. %s  (%s, %s)", i, name, ctype, size))
  end
  return lines
end

function M.auth_lines(auth)
  local lines = { "Authentication Results:", "" }
  if not auth then
    table.insert(lines, "  (unavailable)")
    return lines
  end
  local sections = { "dkim", "spf", "dmarc", "arc" }
  for _, section in ipairs(sections) do
    local checks = auth[section] or {}
    if #checks > 0 then
      table.insert(lines, "  " .. section:upper() .. ":")
      for _, check in ipairs(checks) do
        table.insert(lines, string.format("    %s — %s", check.status or "?", check.details or ""))
      end
      table.insert(lines, "")
    end
  end
  if #lines == 2 then
    table.insert(lines, "  (no authentication results)")
  end
  return lines
end

return M
