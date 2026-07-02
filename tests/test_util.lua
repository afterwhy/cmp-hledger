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


for _, v in ipairs({
  {
    name = 'Latin',
    items = {
      { label = 'Expenses:Drinks:Coffee', kind = 9 },
      { label = 'Expenses:Food:Groceries', kind = 9 },
      { label = 'Income:Salary', kind = 9 },
    },
    r = { row = 3, col = 10, leading = 1, input = 'e:d:c', start_char = 1, end_char = 9 },
    match_across_three = { pat = 'E:D:C', inp = 'e:d:c' },
    no_match           = { pat = 'X:Y',   inp = 'x:y' },
    second_seg_wrong   = { pat = 'E:Z',   inp = 'e:z',   items = { { label = 'Expenses:aZ', kind = 9 } } },
    third_seg_wrong    = { pat = 'E:D:X', inp = 'e:d:x' },
    pattern_too_deep   = { pat = 'E:F:C', inp = 'e:f:c' },
    first_seg_wrong    = { pat = 'X:D:C', inp = 'x:d:c' },
    other_branch_wrong = { pat = 'I:E',   inp = 'i:e' },
    single_char_abbrev = { pat = 'E:a',   inp = 'e:a', label = 'Expenses:aZ' },
    single_seg_match   = { pat = 'E',     inp = 'e' },
    pattern_shorter    = { pat = 'E:D',   inp = 'e:d' },
  },
  {
    name = 'Cyrillic',
    items = {
      { label = 'расходы:подарки:продукты', kind = 9 },
      { label = 'расходы:еда:бакалея', kind = 9 },
      { label = 'доходы:зарплата', kind = 9 },
    },
    r = { row = 3, col = 14, leading = 2, input = 'р:п:п', start_char = 2, end_char = 13 },
    match_across_three = { pat = 'р:п:п', inp = 'р:п:п' },
    no_match           = { pat = 'х:й',   inp = 'х:й' },
    second_seg_wrong   = { pat = 'а:б',   inp = 'а:б',   items = { { label = 'активы:сбережения:вклад:отп', kind = 9 } } },
    third_seg_wrong    = { pat = 'р:п:х', inp = 'р:п:х' },
    pattern_too_deep   = { pat = 'р:е:з', inp = 'р:е:з' },
    first_seg_wrong    = { pat = 'ф:п:п', inp = 'ф:п:п' },
    other_branch_wrong = { pat = 'д:п',   inp = 'д:п' },
    single_char_abbrev = { pat = 'р:а',   inp = 'р:а', label = 'расходы:аз' },
    single_seg_match   = { pat = 'р',     inp = 'р' },
    pattern_shorter    = { pat = 'р:п',   inp = 'р:п' },
  },
}) do
  describe('filter_prefix_mode - ' .. v.name, function()
    local items, r = v.items, v.r

    it('returns matching items with textEdit', function()
      local prefixes = util.split(v.match_across_three.inp, ':')
      local result = util.filter_prefix_mode(items, prefixes, v.match_across_three.inp, 3, r.col, r.leading)
      assert.equal(1, #result)
      assert.equal(items[1].label, result[1].label)
    end)

    it('includes textEdit in result', function()
      local prefixes = util.split(v.match_across_three.inp, ':')
      local result = util.filter_prefix_mode(items, prefixes, v.match_across_three.inp, 3, r.col, r.leading)
      assert.not_nil(result[1].textEdit)
      assert.equal(items[1].label, result[1].textEdit.newText)
    end)

    it('calculates textEdit range correctly', function()
      local prefixes = util.split(v.match_across_three.inp, ':')
      local result = util.filter_prefix_mode(items, prefixes, v.match_across_three.inp, 3, r.col, r.leading)
      local range = result[1].textEdit.range
      assert.equal(2, range.start.line)
      assert.equal(r.start_char, range.start.character)
      assert.equal(2, range['end'].line)
      assert.equal(r.end_char, range['end'].character)
    end)

    it('returns empty when no items match (X:Y vs items)', function()
      local prefixes = util.split(v.no_match.inp, ':')
      local result = util.filter_prefix_mode(items, prefixes, v.no_match.inp, 1, 1, 1)
      assert.same({}, result)
    end)

    it('does not match second seg mismatch (E:Z vs Expenses:aZ)', function()
      local prefixes = util.split(v.second_seg_wrong.inp, ':')
      local test_items = v.second_seg_wrong.items or items
      local result = util.filter_prefix_mode(test_items, prefixes, v.second_seg_wrong.inp, 1, 1, 1)
      assert.same({}, result)
    end)

    it('does not match third seg mismatch (E:D:X vs Drinks:Coffee)', function()
      local prefixes = util.split(v.third_seg_wrong.inp, ':')
      local result = util.filter_prefix_mode(items, prefixes, v.third_seg_wrong.inp, 1, 1, 1)
      assert.same({}, result)
    end)

    it('does not match when pattern deeper than label (E:F:C vs Food)', function()
      local prefixes = util.split(v.pattern_too_deep.inp, ':')
      local result = util.filter_prefix_mode(items, prefixes, v.pattern_too_deep.inp, 1, 1, 1)
      assert.same({}, result)
    end)

    it('does not match first seg mismatch (X:D:C vs Drinks:Coffee)', function()
      local prefixes = util.split(v.first_seg_wrong.inp, ':')
      local result = util.filter_prefix_mode(items, prefixes, v.first_seg_wrong.inp, 1, 1, 1)
      assert.same({}, result)
    end)

    it('does not match second seg in diff branch (I:E vs Salary)', function()
      local prefixes = util.split(v.other_branch_wrong.inp, ':')
      local result = util.filter_prefix_mode(items, prefixes, v.other_branch_wrong.inp, 1, 1, 1)
      assert.same({}, result)
    end)

    it('matches single-letter abbrev across segs (E:a vs Expenses:aZ)', function()
      local prefixes = util.split(v.single_char_abbrev.inp, ':')
      local az_items = { { label = v.single_char_abbrev.label, kind = 9 } }
      local result = util.filter_prefix_mode(az_items, prefixes, v.single_char_abbrev.inp, 1, 1, 1)
      assert.equal(1, #result)
      assert.equal(v.single_char_abbrev.label, result[1].label)
    end)

    it('returns empty table when items list is empty', function()
      local prefixes = util.split(v.pattern_shorter.inp, ':')
      local result = util.filter_prefix_mode({}, prefixes, v.pattern_shorter.inp, 1, 1, 1)
      assert.same({}, result)
    end)

    it('matches multiple items for single prefix (E vs Expenses:**)', function()
      local prefixes = util.split(v.single_seg_match.inp, ':')
      local result = util.filter_prefix_mode(items, prefixes, v.single_seg_match.inp, 1, 1, 1)
      assert.equal(2, #result)
      assert.equal(items[1].label, result[1].label)
      assert.equal(items[2].label, result[2].label)
    end)

    it('matches when pattern shorter than label (E:D vs Drinks:Coffee)', function()
      local prefixes = util.split(v.pattern_shorter.inp, ':')
      local result = util.filter_prefix_mode(items, prefixes, v.pattern_shorter.inp, 1, 1, 1)
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
    two_match = 'exp',
    one_match = 'inc',
    case_sens = 'Exp',
  },
  {
    name = 'Cyrillic',
    items = {
      { label = 'расходы:подарки:продукты', kind = 9 },
      { label = 'расходы:еда:продукты', kind = 9 },
      { label = 'доходы:зарплата', kind = 9 },
    },
    two_match = 'рас',
    one_match = 'дох',
    case_sens = 'Рас',
  },
}) do
  describe('filter_simple_mode - ' .. v.name, function()
    local items = v.items

    it('returns items starting with the prefix', function()
      local result = util.filter_simple_mode(items, v.two_match)
      assert.equal(2, #result)
    end)

    it('does not return items that do not match', function()
      local result = util.filter_simple_mode(items, v.one_match)
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
      local result = util.filter_simple_mode(items, v.case_sens)
      assert.equal(0, #result)
    end)

    it('preserves item structure', function()
      local result = util.filter_simple_mode(items, v.two_match)
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
      local result = util.filter_simple_mode({}, v.two_match)
      assert.same({}, result)
    end)
  end)
end
