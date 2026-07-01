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
end)

describe('build_pattern', function()
  it('builds simple pattern for single prefix', function()
    local pattern, prefix_mode = util.build_pattern('exp')
    assert.equal('exp[%w%-]*', pattern)
    assert.is_false(prefix_mode)
  end)

  it('builds multi-segment pattern for colon-separated input', function()
    local pattern, prefix_mode = util.build_pattern('E:D:C')
    assert.equal('e[%w%-]*:d[%w%-]*:c[%w%-]*', pattern)
    assert.is_true(prefix_mode)
  end)

  it('lowercases each segment', function()
    local pattern, _ = util.build_pattern('ExP:Te')
    assert.equal('exp[%w%-]*:te[%w%-]*', pattern)
  end)

  it('sets prefix_mode to false for single segment after colon removal', function()
    local _, prefix_mode = util.build_pattern('E:')
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
    local pattern, _ = util.build_pattern('E:D:C')
    local result = util.filter_prefix_mode(items, pattern, 'e:d:c', 3, 10, 6)
    assert.equal(1, #result)
    assert.equal('Expenses:Drinks:Coffee', result[1].label)
  end)

  it('includes textEdit in result', function()
    local pattern, _ = util.build_pattern('E:D:C')
    local result = util.filter_prefix_mode(items, pattern, 'e:d:c', 3, 10, 6)
    assert.not_nil(result[1].textEdit)
    assert.equal('e:d:c', result[1].textEdit.filterText)
    assert.equal('Expenses:Drinks:Coffee', result[1].textEdit.newText)
  end)

  it('calculates textEdit range correctly', function()
    local pattern, _ = util.build_pattern('E:D:C')
    local result = util.filter_prefix_mode(items, pattern, 'e:d:c', 3, 10, 6)
    local range = result[1].textEdit.range
    assert.equal(2, range.start.line)
    assert.equal(1, range.start.character) -- offset - #input = 6 - 5 = 1
    assert.equal(2, range['end'].line)
    assert.equal(9, range['end'].character) -- cursor_col - 1 = 10 - 1 = 9
  end)

  it('returns empty when no items match', function()
    local pattern, _ = util.build_pattern('X:Y')
    local result = util.filter_prefix_mode(items, pattern, 'x:y', 1, 1, 1)
    assert.same({}, result)
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
end)
