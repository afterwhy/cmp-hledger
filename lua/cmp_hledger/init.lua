local source = {}
local cmp = require('cmp')
local util = require('cmp_hledger.util')

source.new = function()
  local self = setmetatable({}, { __index = source })
  self.items = nil
  return self
end

source.get_trigger_characters = function()
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
end

local get_items = function(account_path)
  local openPop = assert(io.popen(vim.b.hledger_bin .. ' accounts -f ' .. account_path))
  local output = openPop:read('*all')
  openPop:close()
  local t = util.split(output, '\n')
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
  local pattern, prefix_mode = util.build_pattern(input)
  local items = {}
  if prefix_mode then
    items = util.filter_prefix_mode(
      self.items, pattern, input,
      request.context.cursor.row,
      request.context.cursor.col,
      request.offset
    )
  else
    items = util.filter_simple_mode(self.items, input)
  end
  callback(items)
end

return source
