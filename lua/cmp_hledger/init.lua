local source = {}
local cmp = require('cmp')
local util = require('cmp_hledger.util')

source.new = function()
  local self = setmetatable({}, { __index = source })
  self.items = nil
  self._cached_path = nil
  self._cached_mtime = nil
  return self
end

source.get_keyword_pattern = function()
  return '[[:lower:][:upper:]0-9_.:-]*'
end

source.get_trigger_characters = function()
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
end

local get_items = function(account_path)
  local openPop = assert(io.popen(vim.b.hledger_bin .. ' accounts -f ' .. account_path))
  local output = openPop:read('*all')
  openPop:close()
  local t = util.split(output, "\n")

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
  if vim.fn.executable("hledger") == 1 then
    vim.b.hledger_bin = "hledger"
  elseif vim.fn.executable("ledger") == 1 then
    vim.b.hledger_bin = "ledger"
  else
    vim.api.nvim_echo({
      { 'cmp_hledger',                         'ErrorMsg' },
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

  local input = util.ltrim(request.context.cursor_before_line):lower()
  local prefixes = util.split(input, ":")
  local is_abbrev = #prefixes > 1

  local items = {}
  if is_abbrev then
    items = util.filter_prefix_mode(self.items, prefixes, input,
      request.context.cursor.row, request.context.cursor.col, request.offset)
  else
    items = util.filter_simple_mode(self.items, input)
  end
  callback(items)
end

return source
