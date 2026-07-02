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
  local prefixes = {}
  for _, p in ipairs(M.split(input, ':')) do
    prefixes[#prefixes + 1] = p:lower()
  end
  return prefixes, #prefixes > 1
end

function M.filter_prefix_mode(items, prefixes, input, cursor_row, cursor_col, leading)
  local result = {}
  for _, item in ipairs(items) do
    local label_segments = M.split(item.label:lower(), ':')
    local seg_idx = 1
    local all_match = true
    for _, prefix in ipairs(prefixes) do
      local found = false
      for j = seg_idx, #label_segments do
        if M.startswith(label_segments[j], prefix) then
          seg_idx = j + 1
          found = true
          break
        end
      end
      if not found then
        all_match = false
        break
      end
    end
    if all_match then
      table.insert(result, {
        word = item.label,
        label = item.label,
        kind = item.kind,
        filterText = input,
        textEdit = {
          filterText = input,
          newText = item.label,
          range = {
            start = {
              line = cursor_row - 1,
              character = leading,
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
