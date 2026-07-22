local M = {}

function M.ltrim(s)
  return s:match('^%s*(.*)')
end

function M.split(str, sep)
  local t = {}
  for s in string.gmatch(str, '([^' .. sep .. ']+)') do
    table.insert(t, s)
  end
  return t
end

function M.startswith(str, prefix)
  return str:sub(1, #prefix) == prefix
end

return M
