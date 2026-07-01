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

function M.build_pattern(input)
  local prefixes = M.split(input, ':')
  local pattern = ''
  for i, prefix in ipairs(prefixes) do
    if i == 1 then
      pattern = string.format('%s[%%w%%-]*', prefix:lower())
    else
      pattern = string.format('%s:%s[%%w%%-]*', pattern, prefix:lower())
    end
  end
  return pattern, #prefixes > 1 and pattern ~= ''
end

function M.filter_prefix_mode(items, pattern, input, cursor_row, cursor_col, offset)
  local result = {}
  for _, item in ipairs(items) do
    if string.match(item.label:lower(), pattern) then
      table.insert(result, {
        word = item.label,
        label = item.label,
        kind = item.kind,
        textEdit = {
          filterText = input,
          newText = item.label,
          range = {
            start = {
              line = cursor_row - 1,
              character = offset - #input,
            },
            ['end'] = {
              line = cursor_row - 1,
              character = cursor_col - 1,
            },
          },
        },
      })
    end
  end
  return result
end

function M.filter_simple_mode(items, input)
  local result = {}
  for _, item in ipairs(items) do
    if M.startswith(item.label:lower(), input) then
      table.insert(result, item)
    end
  end
  return result
end

return M
