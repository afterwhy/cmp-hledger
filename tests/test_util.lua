local util = require('cmp_hledger.util')

describe('ltrim', function()
  it('trims leading spaces', function()
    assert.equal('foo', util.ltrim('  foo'))
  end)

  it('does not trim trailing spaces', function()
    assert.equal('foo  ', util.ltrim('foo  '))
  end)

  it('returns empty string for all spaces', function()
    assert.equal('', util.ltrim('   '))
  end)

  it('returns empty string for empty input', function()
    assert.equal('', util.ltrim(''))
  end)

  it('returns string unchanged when no leading spaces', function()
    assert.equal('foo', util.ltrim('foo'))
  end)
end)

describe('split', function()
  it('splits by colon', function()
    assert.same({ 'a', 'b', 'c' }, util.split('a:b:c', ':'))
  end)

  it('returns single item when no separator present', function()
    assert.same({ 'abc' }, util.split('abc', ':'))
  end)

  it('returns empty table for empty string', function()
    assert.same({}, util.split('', ':'))
  end)

  it('skips empty segments', function()
    assert.same({ 'a', 'b' }, util.split('a::b', ':'))
  end)

  it('returns empty for only colons', function()
    assert.same({}, util.split(':::', ':'))
  end)
end)

describe('startswith', function()
  it('returns true when string starts with prefix', function()
    assert.is_true(util.startswith('Expenses:Food', 'Exp'))
  end)

  it('returns false when string does not start with prefix', function()
    assert.is_false(util.startswith('Income:Salary', 'Exp'))
  end)

  it('returns true for empty prefix', function()
    assert.is_true(util.startswith('Expenses', ''))
  end)

  it('returns false when prefix is longer than string', function()
    assert.is_false(util.startswith('Exp', 'Expenses'))
  end)

  it('is case-sensitive', function()
    assert.is_false(util.startswith('Expenses', 'exp'))
  end)

  it('returns true when strings are identical', function()
    assert.is_true(util.startswith('Expenses:Food', 'Expenses:Food'))
  end)

  it('returns true for two empty strings', function()
    assert.is_true(util.startswith('', ''))
  end)
end)

describe('build_pattern', function()
  it('returns single-element table for single prefix', function()
    local prefixes, prefix_mode = util.build_pattern('exp')
    assert.same({ 'exp' }, prefixes)
    assert.is_false(prefix_mode)
  end)

  it('returns lowered table for colon-separated input', function()
    local prefixes, prefix_mode = util.build_pattern('E:D:C')
    assert.same({ 'e', 'd', 'c' }, prefixes)
    assert.is_true(prefix_mode)
  end)

  it('lowercases each segment', function()
    local prefixes = util.build_pattern('ExP:Te')
    assert.same({ 'exp', 'te' }, prefixes)
  end)

  it('sets prefix_mode to false for single segment after colon removal', function()
    local _, prefix_mode = util.build_pattern('E:')
    assert.is_false(prefix_mode)
  end)

  it('handles double colons by skipping empty segments', function()
    local prefixes, prefix_mode = util.build_pattern('a::b')
    assert.same({ 'a', 'b' }, prefixes)
    assert.is_true(prefix_mode)
  end)

  it('returns empty table for only colons', function()
    local prefixes, prefix_mode = util.build_pattern(':::')
    assert.same({}, prefixes)
    assert.is_false(prefix_mode)
  end)
end)

describe('filter_prefix_mode', function()
  local items = {
    { label = 'Expenses:Drinks:Coffee', kind = 9 },
    { label = 'Expenses:Food:Groceries', kind = 9 },
    { label = 'Income:Salary', kind = 9 },
  }

  it('returns matching items with textEdit', function()
    local prefixes, _ = util.build_pattern('E:D:C')
    local result = util.filter_prefix_mode(items, prefixes, 'e:d:c', 3, 10, 6)
    assert.equal(1, #result)
    assert.equal('Expenses:Drinks:Coffee', result[1].label)
  end)

  it('includes textEdit in result', function()
    local prefixes, _ = util.build_pattern('E:D:C')
    local result = util.filter_prefix_mode(items, prefixes, 'e:d:c', 3, 10, 6)
    assert.not_nil(result[1].textEdit)
    assert.equal('e:d:c', result[1].textEdit.filterText)
    assert.equal('Expenses:Drinks:Coffee', result[1].textEdit.newText)
  end)

  it('calculates textEdit range correctly', function()
    local prefixes, _ = util.build_pattern('E:D:C')
    local result = util.filter_prefix_mode(items, prefixes, 'e:d:c', 3, 10, 6)
    local range = result[1].textEdit.range
    assert.equal(2, range.start.line)
    assert.equal(1, range.start.character) -- offset - #input = 6 - 5 = 1
    assert.equal(2, range['end'].line)
    assert.equal(9, range['end'].character) -- cursor_col - 1 = 10 - 1 = 9
  end)

  it('returns empty when no items match', function()
    local prefixes, _ = util.build_pattern('X:Y')
    local result = util.filter_prefix_mode(items, prefixes, 'x:y', 1, 1, 1)
    assert.same({}, result)
  end)

  it('does not match second segment mismatch (E:Z vs Expenses:aZ)', function()
    local prefixes, _ = util.build_pattern('E:Z')
    local result = util.filter_prefix_mode(items, prefixes, 'e:z', 1, 1, 1)
    assert.same({}, result)
  end)

  it('does not match third segment mismatch (E:D:X vs Drinks:Coffee)', function()
    local prefixes, _ = util.build_pattern('E:D:X')
    local result = util.filter_prefix_mode(items, prefixes, 'e:d:x', 1, 1, 1)
    assert.same({}, result)
  end)

  it('does not match when pattern is deeper than label (E:F:C vs Food)', function()
    local prefixes, _ = util.build_pattern('E:F:C')
    local result = util.filter_prefix_mode(items, prefixes, 'e:f:c', 1, 1, 1)
    assert.same({}, result)
  end)

  it('does not match first segment mismatch (X:D:C vs Drinks:Coffee)', function()
    local prefixes, _ = util.build_pattern('X:D:C')
    local result = util.filter_prefix_mode(items, prefixes, 'x:d:c', 1, 1, 1)
    assert.same({}, result)
  end)

  it('does not match second segment mismatch (I:E vs Salary)', function()
    local prefixes, _ = util.build_pattern('I:E')
    local result = util.filter_prefix_mode(items, prefixes, 'i:e', 1, 1, 1)
    assert.same({}, result)
  end)

  it('matches E:a against Expenses:aZ', function()
    local prefixes, _ = util.build_pattern('E:a')
    local az_items = {
      { label = 'Expenses:aZ', kind = 9 },
    }
    local result = util.filter_prefix_mode(az_items, prefixes, 'e:a', 1, 1, 1)
    assert.equal(1, #result)
    assert.equal('Expenses:aZ', result[1].label)
  end)

  it('returns empty table when items list is empty', function()
    local prefixes, _ = util.build_pattern('E:D')
    local result = util.filter_prefix_mode({}, prefixes, 'e:d', 1, 1, 1)
    assert.same({}, result)
  end)

  it('matches multiple items for same pattern', function()
    local prefixes, _ = util.build_pattern('E')
    local result = util.filter_prefix_mode(items, prefixes, 'e', 1, 1, 1)
    assert.equal(2, #result)
    assert.equal('Expenses:Drinks:Coffee', result[1].label)
    assert.equal('Expenses:Food:Groceries', result[2].label)
  end)

  it('matches when pattern is shorter than label segments', function()
    local prefixes, _ = util.build_pattern('E:D')
    local result = util.filter_prefix_mode(items, prefixes, 'e:d', 1, 1, 1)
    assert.equal(1, #result)
    assert.equal('Expenses:Drinks:Coffee', result[1].label)
  end)
end)

describe('filter_simple_mode', function()
  local items = {
    { label = 'Expenses:Drinks:Coffee', kind = 9 },
    { label = 'Expenses:Food:Groceries', kind = 9 },
    { label = 'Income:Salary', kind = 9 },
  }

  it('returns items starting with the prefix', function()
    local result = util.filter_simple_mode(items, 'exp')
    assert.equal(2, #result)
  end)

  it('does not return items that do not match', function()
    local result = util.filter_simple_mode(items, 'inc')
    assert.equal(1, #result)
    assert.equal('Income:Salary', result[1].label)
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
    local result = util.filter_simple_mode(items, 'Exp')
    assert.equal(0, #result)
  end)

  it('preserves item structure', function()
    local result = util.filter_simple_mode(items, 'exp')
    assert.equal(9, result[1].kind)
    assert.equal('Expenses:Drinks:Coffee', result[1].label)
  end)

  it('matches exact label', function()
    local result = util.filter_simple_mode(items, 'expenses:drinks:coffee')
    assert.equal(1, #result)
    assert.equal('Expenses:Drinks:Coffee', result[1].label)
  end)

  it('returns empty when prefix is longer than any label', function()
    local result = util.filter_simple_mode(items, 'expenses:drinks:coffee:extra')
    assert.same({}, result)
  end)

  it('returns empty table for empty items list', function()
    local result = util.filter_simple_mode({}, 'exp')
    assert.same({}, result)
  end)
end)
