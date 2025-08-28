---@module "luassert"

local duration = require('timer.duration')
local u = require('timer.unit')

describe('from', function()
  it('defaults to 0 when no argument', function()
    local d = duration.from()
    assert.are.equal(0, d:asMilliseconds())
  end)

  it('accepts positive milliseconds', function()
    local d = duration.from(1234)
    assert.are.equal(1234, d:asMilliseconds())
  end)

  it('accepts zero', function()
    local d = duration.from(0)
    assert.are.equal(0, d:asMilliseconds())
  end)

  it('accepts negative milliseconds', function()
    local d = duration.from(-500)
    assert.are.equal(0, d:asMilliseconds())
  end)
end)

describe('Duration:sub', function()
  it('subtracts smaller duration correctly', function()
    local d1 = duration.from(5000)
    local d2 = duration.from(2000)
    local result = d1:sub(d2)
    assert.are.equal(3000, result:asMilliseconds())
  end)

  it('subtracts larger duration clamps to zero', function()
    local d1 = duration.from(1000)
    local d2 = duration.from(3000)
    local result = d1:sub(d2)
    assert.are.equal(0, result:asMilliseconds()) -- negative not allowed
  end)

  it('subtracting zero returns the same duration', function()
    local d1 = duration.from(1234)
    local d2 = duration.from(0)
    local result = d1:sub(d2)
    assert.are.equal(1234, result:asMilliseconds())
  end)

  it('subtracting itself returns zero', function()
    local d1 = duration.from(9876)
    local result = d1:sub(d1)
    assert.are.equal(0, result:asMilliseconds())
  end)
end)

describe('parse_format', function()
  it('parses seconds correctly', function()
    local d = duration.parse_format('45s')
    assert.are.equal(45 * u.SECOND, d:asMilliseconds())
  end)

  it('parses minutes correctly', function()
    local d = duration.parse_format('3m')
    assert.are.equal(3 * u.MINUTE, d:asMilliseconds())
  end)

  it('parses fractional minutes', function()
    local d = duration.parse_format('3.5m')
    assert.are.equal(3 * u.MINUTE + 0.5 * u.MINUTE, d:asMilliseconds())
  end)

  it('parses hours correctly', function()
    local d = duration.parse_format('1h')
    assert.are.equal(1 * u.HOUR, d:asMilliseconds())
  end)

  it('parses fractional hours', function()
    local d = duration.parse_format('1.75h')
    assert.are.equal(1 * u.HOUR + 0.75 * u.HOUR, d:asMilliseconds())
  end)

  it('parses values without unit as milliseconds', function()
    local d = duration.parse_format('500')
    assert.are.equal(500, d:asMilliseconds())
  end)

  it('throws on invalid character', function()
    assert.has_error(function() duration.parse_format('3x') end, 'Unexpected char: x')
  end)
end)

describe('Duration:into_hms', function()
  it('formats durations less than 1 minute as seconds', function()
    local d = duration.from(45 * u.SECOND)
    assert.is_equal('45s', d:into_hms())
  end)

  it('formats durations between 1 minute and 1 hour as m:ss', function()
    local d = duration.from(u.MINUTE + 15 * u.SECOND)
    assert.is_equal('1:15', d:into_hms())

    local d2 = duration.from(59 * u.MINUTE + 59 * u.SECOND)
    assert.is_equal('59:59', d2:into_hms())
  end)

  it('formats durations of 1 hour or more as hh:mm:ss', function()
    local d = duration.from(u.HOUR) -- exactly 1h
    assert.is_equal('01:00:00', d:into_hms())

    local d2 = duration.from(u.HOUR + u.MINUTE + u.SECOND) -- 1h 1m 1s
    assert.is_equal('01:01:01', d2:into_hms())

    local d3 = duration.from(2 * u.HOUR + 2 * u.MINUTE + 2 * u.SECOND) -- 2h 2m 2s
    assert.is_equal('02:02:02', d3:into_hms())
  end)

  it('handles zero duration', function()
    local d = duration.from(0)
    assert.is_equal(nil, d:into_hms())
  end)
end)
