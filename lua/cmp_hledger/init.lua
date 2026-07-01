local source = {}
local cmp = require('cmp')
local util = require('cmp_hledger.util')

source.new = function()
  local self = setmetatable({}, { __index = source })
  self.items = nil
  return self
end

source.get_trigger_characters = function()
<<<<<<< Updated upstream
  return {
    'Ex',
    'In',
    'As',
    'Li',
    'Eq',
    'E:',
    'I:',
    'A:',
    'L:',
  }
=======
  if vim.bo.filetype ~= 'ledger' then
    return {}
  end

  local triggers = { 'E', 'I', 'A', 'L' }

  local buf = vim.api.nvim_get_current_buf()
  if buf and vim.api.nvim_buf_is_valid(buf) then
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local seen = {}
    for _, line in ipairs(lines) do
      local name = line:match("^account%s+([^%s;]+)%s*;%s*type:")
      if name then
        local segment = name:match("^([^:]+)")
        if segment then
          local char = segment:sub(1, 1)
          if not seen[char] then
            seen[char] = true
            table.insert(triggers, char)
          end
        end
      end
    end
  end

  return triggers
>>>>>>> Stashed changes
end

local get_items = function(account_path)
  local openPop = assert(io.popen(vim.b.hledger_bin .. ' accounts -f ' .. account_path))
  local output = openPop:read('*all')
  openPop:close()
<<<<<<< Updated upstream
  local t = util.split(output, '\n')
=======
  local t = util.split(output, "\n")

>>>>>>> Stashed changes
  local items = {}
  for _, s in pairs(t) do
    table.insert(items, {
      label = s,
      kind = cmp.lsp.CompletionItemKind.Property,
    })
  end
  return items
end

source.complete = function(self, request, callback)
  if vim.bo.filetype ~= 'ledger' then
    callback()
    return
  end
  if vim.fn.executable('hledger') == 1 then
    vim.b.hledger_bin = 'hledger'
  elseif vim.fn.executable('ledger') == 1 then
    vim.b.hledger_bin = 'ledger'
  else
    vim.api.nvim_echo({
      { 'cmp_hledger', 'ErrorMsg' },
      { ' ' .. "Can't find hledger or ledger" },
    }, true, {})
    callback()
    return
  end
  local account_path = vim.api.nvim_buf_get_name(0)
  if not self.items then
    self.items = get_items(account_path)
  end

  local input = util.ltrim(request.context.cursor_before_line):lower()
<<<<<<< Updated upstream
  local pattern, prefix_mode = util.build_pattern(input)
  local items = {}
  if prefix_mode then
    items = util.filter_prefix_mode(
      self.items, pattern, input,
      request.context.cursor.row,
      request.context.cursor.col,
      request.offset
    )
=======
  local prefixes = util.split(input, ":")
  local is_abbrev = #prefixes > 1

  local items = {}
  if is_abbrev then
    items = util.filter_prefix_mode(self.items, prefixes, input,
      request.context.cursor.row, request.context.cursor.col, request.offset)
>>>>>>> Stashed changes
  else
    items = util.filter_simple_mode(self.items, input)
  end
  callback(items)
end

return source
