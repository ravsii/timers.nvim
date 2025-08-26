---@module "luassert"

local Duration = require('timer.duration')

describe('Duration.new', function()
  it('defaults to 0 when no argument', function()
    local d = Duration.new()
    assert.are.equal(0, d:asMilliseconds())
  end)

  it('accepts positive milliseconds', function()
    local d = Duration.new(1234)
    assert.are.equal(1234, d:asMilliseconds())
  end)

  it('accepts zero', function()
    local d = Duration.new(0)
    assert.are.equal(0, d:asMilliseconds())
  end)

  it('accepts negative milliseconds', function()
    local d = Duration.new(-500)
    assert.are.equal(-500, d:asMilliseconds())
  end)
end)

describe('Duration.parse', function()
  it('parses seconds correctly', function()
    local d = Duration.parse('45s')
    assert.are.equal(45 * Duration.SECOND, d:asMilliseconds())
  end)

  it('parses minutes correctly', function()
    local d = Duration.parse('3m')
    assert.are.equal(3 * Duration.MINUTE, d:asMilliseconds())
  end)

  it('parses fractional minutes', function()
    local d = Duration.parse('3.5m')
    assert.are.equal(3 * Duration.MINUTE + 0.5 * Duration.MINUTE, d:asMilliseconds())
  end)

  it('parses hours correctly', function()
    local d = Duration.parse('1h')
    assert.are.equal(1 * Duration.HOUR, d:asMilliseconds())
  end)

  it('parses fractional hours', function()
    local d = Duration.parse('1.75h')
    assert.are.equal(1 * Duration.HOUR + 0.75 * Duration.HOUR, d:asMilliseconds())
  end)

  it('parses values without unit as milliseconds', function()
    local d = Duration.parse('500')
    assert.are.equal(500, d:asMilliseconds())
  end)

  it('throws on invalid character', function()
    assert.has_error(function() Duration.parse('3x') end, 'Unexpected char: x')
  end)
end)
