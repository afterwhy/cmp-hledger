local util = require('cmp_hledger.util')

describe('ltrim', function()
  local scenarios = {
    { desc = 'trims leading spaces',          latin = { '  foo', 'foo' },          cyrillic = { '  расходы', 'расходы' } },
    { desc = 'does not trim trailing spaces', latin = { 'foo  ', 'foo  ' },        cyrillic = { 'расходы  ', 'расходы  ' } },
    { desc = 'returns empty string for all spaces', latin = { '   ', '' },         cyrillic = { '   ', '' } },
    { desc = 'returns empty string for empty input', latin = { '', '' },           cyrillic = { '', '' } },
    { desc = 'returns string unchanged',           latin = { 'foo', 'foo' },       cyrillic = { 'доходы', 'доходы' } },
  }
  for _, s in ipairs(scenarios) do
    for _, lang in ipairs({ 'latin', 'cyrillic' }) do
      it(s.desc .. ' - ' .. lang, function()
        assert.equal(s[lang][2], util.ltrim(s[lang][1]))
      end)
    end
  end
end)

describe('split', function()
  local scenarios = {
    { desc = 'splits by colon',
      latin = { 'a:b:c', { 'a', 'b', 'c' } },
      cyrillic = { 'а:б:в', { 'а', 'б', 'в' } } },
    { desc = 'returns single item when no separator present',
      latin = { 'abc', { 'abc' } },
      cyrillic = { 'абв', { 'абв' } } },
    { desc = 'returns empty table for empty string',
      latin = { '', {} },
      cyrillic = { '', {} } },
    { desc = 'skips empty segments',
      latin = { 'a::b', { 'a', 'b' } },
      cyrillic = { 'а::б', { 'а', 'б' } } },
    { desc = 'returns empty for only colons',
      latin = { ':::', {} },
      cyrillic = { ':::', {} } },
  }
  for _, s in ipairs(scenarios) do
    for _, lang in ipairs({ 'latin', 'cyrillic' }) do
      it(s.desc .. ' - ' .. lang, function()
        assert.same(s[lang][2], util.split(s[lang][1], ':'))
      end)
    end
  end
end)

describe('startswith', function()
  local scenarios = {
    { desc = 'returns true when string starts with prefix',
      latin = { 'Expenses:Food', 'Exp', true },
      cyrillic = { 'расходы:подарки', 'рас', true } },
    { desc = 'returns false when string does not start with prefix',
      latin = { 'Income:Salary', 'Exp', false },
      cyrillic = { 'доходы:зарплата', 'рас', false } },
    { desc = 'returns true for empty prefix',
      latin = { 'Expenses', '', true },
      cyrillic = { 'расходы', '', true } },
    { desc = 'returns false when prefix is longer than string',
      latin = { 'Exp', 'Expenses', false },
      cyrillic = { 'рас', 'расходы', false } },
    { desc = 'is case-sensitive',
      latin = { 'Expenses', 'exp', false },
      cyrillic = { 'расходы', 'Рас', false } },
    { desc = 'returns true when strings are identical',
      latin = { 'Expenses:Food', 'Expenses:Food', true },
      cyrillic = { 'расходы:подарки', 'расходы:подарки', true } },
    { desc = 'returns true for two empty strings',
      latin = { '', '', true },
      cyrillic = { '', '', true } },
  }
  for _, s in ipairs(scenarios) do
    for _, lang in ipairs({ 'latin', 'cyrillic' }) do
      it(s.desc .. ' - ' .. lang, function()
        local fn = s[lang][3] and assert.is_true or assert.is_false
        fn(util.startswith(s[lang][1], s[lang][2]))
      end)
    end
  end
end)

describe('build_pattern', function()
  local scenarios = {
    { desc = 'returns single-element table for single prefix',
      latin = { 'exp', { 'exp' }, false },
      cyrillic = { 'рас', { 'рас' }, false } },
    { desc = 'returns lowered table for colon-separated input',
      latin = { 'E:D:C', { 'e', 'd', 'c' }, true },
      cyrillic = { 'р:п:п', { 'р', 'п', 'п' }, true } },
    { desc = 'lowercases each segment',
      latin = { 'ExP:Te', { 'exp', 'te' } },
      cyrillic = { 'рас:про', { 'рас', 'про' } } },
    { desc = 'sets prefix_mode to false for single segment after colon removal',
      latin = { 'E:', nil, false },
      cyrillic = { 'р:', nil, false } },
    { desc = 'handles double colons by skipping empty segments',
      latin = { 'a::b', { 'a', 'b' }, true },
      cyrillic = { 'а::б', { 'а', 'б' }, true } },
    { desc = 'returns empty table for only colons',
      latin = { ':::', {}, false },
      cyrillic = { ':::', {}, false } },
  }
  for _, s in ipairs(scenarios) do
    for _, lang in ipairs({ 'latin', 'cyrillic' }) do
      it(s.desc .. ' - ' .. lang, function()
        local prefixes, mode = util.build_pattern(s[lang][1])
        if s[lang][2] ~= nil then
          assert.same(s[lang][2], prefixes)
        end
        if s[lang][3] ~= nil then
          assert.are.equal(s[lang][3], mode)
        end
      end)
    end
  end
end)

for _, v in ipairs({
  {
    name = 'Latin',
    items = {
      { label = 'Expenses:Drinks:Coffee', kind = 9 },
      { label = 'Expenses:Food:Groceries', kind = 9 },
      { label = 'Income:Salary', kind = 9 },
    },
    r = { row = 3, col = 10, offset = 6, input = 'e:d:c', start_char = 1, end_char = 9 },
    c = {
      three     = { pat = 'E:D:C', inp = 'e:d:c' },
      empty     = { pat = 'X:Y', inp = 'x:y' },
      sec_mis   = { pat = 'E:Z', inp = 'e:z' },
      third_mis = { pat = 'E:D:X', inp = 'e:d:x' },
      deep      = { pat = 'E:F:C', inp = 'e:f:c' },
      first_mis = { pat = 'X:D:C', inp = 'x:d:c' },
      sal_mis   = { pat = 'I:E', inp = 'i:e' },
      ea        = { pat = 'E:a', inp = 'e:a', label = 'Expenses:aZ' },
      ed        = { pat = 'E:D', inp = 'e:d' },
      single    = { pat = 'E', inp = 'e' },
    },
  },
  {
    name = 'Cyrillic',
    items = {
      { label = 'расходы:подарки:продукты', kind = 9 },
      { label = 'расходы:еда:бакалея', kind = 9 },
      { label = 'доходы:зарплата', kind = 9 },
    },
    r = { row = 3, col = 14, offset = 10, input = 'р:п:п', start_char = 2, end_char = 13 },
    c = {
      three     = { pat = 'р:п:п', inp = 'р:п:п' },
      empty     = { pat = 'х:й', inp = 'х:й' },
      sec_mis   = { pat = 'р:з', inp = 'р:з' },
      third_mis = { pat = 'р:п:х', inp = 'р:п:х' },
      deep      = { pat = 'р:е:з', inp = 'р:е:з' },
      first_mis = { pat = 'ф:п:п', inp = 'ф:п:п' },
      sal_mis   = { pat = 'д:п', inp = 'д:п' },
      ea        = { pat = 'р:а', inp = 'р:а', label = 'расходы:аз' },
      ed        = { pat = 'р:п', inp = 'р:п' },
      single    = { pat = 'р', inp = 'р' },
    },
  },
}) do
  describe('filter_prefix_mode - ' .. v.name, function()
    local c, items, r = v.c, v.items, v.r

    it('returns matching items with textEdit', function()
      local prefixes, _ = util.build_pattern(c.three.pat)
      local result = util.filter_prefix_mode(items, prefixes, c.three.inp, 3, r.col, r.offset)
      assert.equal(1, #result)
      assert.equal(items[1].label, result[1].label)
    end)

    it('includes textEdit in result', function()
      local prefixes, _ = util.build_pattern(c.three.pat)
      local result = util.filter_prefix_mode(items, prefixes, c.three.inp, 3, r.col, r.offset)
      assert.not_nil(result[1].textEdit)
      assert.equal(r.input, result[1].textEdit.filterText)
      assert.equal(items[1].label, result[1].textEdit.newText)
    end)

    it('calculates textEdit range correctly', function()
      local prefixes, _ = util.build_pattern(c.three.pat)
      local result = util.filter_prefix_mode(items, prefixes, c.three.inp, 3, r.col, r.offset)
      local range = result[1].textEdit.range
      assert.equal(2, range.start.line)
      assert.equal(r.start_char, range.start.character)
      assert.equal(2, range['end'].line)
      assert.equal(r.end_char, range['end'].character)
    end)

    it('returns empty when no items match', function()
      local prefixes, _ = util.build_pattern(c.empty.pat)
      local result = util.filter_prefix_mode(items, prefixes, c.empty.inp, 1, 1, 1)
      assert.same({}, result)
    end)

    it('does not match second segment mismatch', function()
      local prefixes, _ = util.build_pattern(c.sec_mis.pat)
      local result = util.filter_prefix_mode(items, prefixes, c.sec_mis.inp, 1, 1, 1)
      assert.same({}, result)
    end)

    it('does not match third segment mismatch', function()
      local prefixes, _ = util.build_pattern(c.third_mis.pat)
      local result = util.filter_prefix_mode(items, prefixes, c.third_mis.inp, 1, 1, 1)
      assert.same({}, result)
    end)

    it('does not match when pattern is deeper than label', function()
      local prefixes, _ = util.build_pattern(c.deep.pat)
      local result = util.filter_prefix_mode(items, prefixes, c.deep.inp, 1, 1, 1)
      assert.same({}, result)
    end)

    it('does not match first segment mismatch', function()
      local prefixes, _ = util.build_pattern(c.first_mis.pat)
      local result = util.filter_prefix_mode(items, prefixes, c.first_mis.inp, 1, 1, 1)
      assert.same({}, result)
    end)

    it('does not match second segment in different branch', function()
      local prefixes, _ = util.build_pattern(c.sal_mis.pat)
      local result = util.filter_prefix_mode(items, prefixes, c.sal_mis.inp, 1, 1, 1)
      assert.same({}, result)
    end)

    it('matches single-letter abbreviation across segments', function()
      local prefixes, _ = util.build_pattern(c.ea.pat)
      local az_items = { { label = c.ea.label, kind = 9 } }
      local result = util.filter_prefix_mode(az_items, prefixes, c.ea.inp, 1, 1, 1)
      assert.equal(1, #result)
      assert.equal(c.ea.label, result[1].label)
    end)

    it('returns empty table when items list is empty', function()
      local prefixes, _ = util.build_pattern(c.ed.pat)
      local result = util.filter_prefix_mode({}, prefixes, c.ed.inp, 1, 1, 1)
      assert.same({}, result)
    end)

    it('matches multiple items for same pattern', function()
      local prefixes, _ = util.build_pattern(c.single.pat)
      local result = util.filter_prefix_mode(items, prefixes, c.single.inp, 1, 1, 1)
      assert.equal(2, #result)
      assert.equal(items[1].label, result[1].label)
      assert.equal(items[2].label, result[2].label)
    end)

    it('matches when pattern is shorter than label segments', function()
      local prefixes, _ = util.build_pattern(c.ed.pat)
      local result = util.filter_prefix_mode(items, prefixes, c.ed.inp, 1, 1, 1)
      assert.equal(1, #result)
      assert.equal(items[1].label, result[1].label)
    end)
  end)
end

for _, v in ipairs({
  {
    name = 'Latin',
    items = {
      { label = 'Expenses:Drinks:Coffee', kind = 9 },
      { label = 'Expenses:Food:Groceries', kind = 9 },
      { label = 'Income:Salary', kind = 9 },
    },
  },
  {
    name = 'Cyrillic',
    items = {
      { label = 'расходы:подарки:продукты', kind = 9 },
      { label = 'расходы:еда:продукты', kind = 9 },
      { label = 'доходы:зарплата', kind = 9 },
    },
  },
}) do
  describe('filter_simple_mode - ' .. v.name, function()
    local items = v.items

    it('returns items starting with the prefix', function()
      local result = util.filter_simple_mode(items, v.name == 'Latin' and 'exp' or 'рас')
      assert.equal(2, #result)
    end)

    it('does not return items that do not match', function()
      local result = util.filter_simple_mode(items, v.name == 'Latin' and 'inc' or 'дох')
      assert.equal(1, #result)
      assert.equal(items[3].label, result[1].label)
    end)

    it('returns empty for non-matching prefix', function()
      local result = util.filter_simple_mode(items, 'zzz')
      assert.same({}, result)
    end)

    it('returns all items for empty prefix', function()
      local result = util.filter_simple_mode(items, '')
      assert.equal(3, #result)
    end)

    it('is case-sensitive (input is expected pre-lowered)', function()
      local result = util.filter_simple_mode(items, v.name == 'Latin' and 'Exp' or 'Рас')
      assert.equal(0, #result)
    end)

    it('preserves item structure', function()
      local result = util.filter_simple_mode(items, v.name == 'Latin' and 'exp' or 'рас')
      assert.equal(9, result[1].kind)
      assert.equal(items[1].label, result[1].label)
    end)

    it('matches exact label', function()
      local result = util.filter_simple_mode(items, items[1].label:lower())
      assert.equal(1, #result)
      assert.equal(items[1].label, result[1].label)
    end)

    it('returns empty when prefix is longer than any label', function()
      local result = util.filter_simple_mode(items, items[1].label:lower() .. ':extra')
      assert.same({}, result)
    end)

    it('returns empty table for empty items list', function()
      local result = util.filter_simple_mode({}, v.name == 'Latin' and 'exp' or 'рас')
      assert.same({}, result)
    end)
  end)
end
