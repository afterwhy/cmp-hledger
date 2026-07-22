local source = {}
local cmp = require('cmp')
local util = require('cmp_hledger.util')

source.new = function()
  local self = setmetatable({}, { __index = source })
  self.items = nil
  return self
end

source.get_keyword_pattern = function()
  return '[[:lower:][:upper:]0-9_.-]*'
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
      { ' ' .. 'Can\'t find hledger or ledger' },
    }, true, {})
    callback()
    return
  end
  local account_path = vim.api.nvim_buf_get_name(0)
  local mtime = vim.fn.getftime(account_path)
  if not self.items or self._cached_path ~= account_path or self._cached_mtime ~= mtime then
    self.items = get_items(account_path)
    self._cached_path = account_path
    self._cached_mtime = mtime
  end

  local cursor_before_line = request.context.cursor_before_line
  local input = util.ltrim(cursor_before_line):lower()
  local leading = #cursor_before_line - #util.ltrim(cursor_before_line)
  local prefixes = util.split(input, ":")
  local is_abbrev = #prefixes > 1

  local items = {}
  if is_abbrev then
    items = util.filter_prefix_mode(self.items, prefixes, input,
      request.context.cursor.row, request.context.cursor.col, leading)
  else
    items = util.filter_simple_mode(self.items, input)
  end
  callback(items)
end

return source
