---@module "luassert"

-- Inject mocks before requiring Timer
package.loaded["timers.config"] = {
  default_timer = {
    message = "default message",
    icon = "⏰",
    title = "Timer",
    log_level = 2,
  },
}

local dur = require("timers.duration")
local t = require("timers.timer")
local u = require("timers.unit")

describe("Timer.new", function()
  it("creates a timer from Duration", function()
    local d = dur.from(5000)
    local tm = t.new(d, { message = "hello" })
    assert.is_truthy(tm)
    assert.are.equal("hello", tm.message)
    assert.are.equal(d, tm.duration)
    assert.is_number(tm.created_at)
  end)

  it("creates a timer from number", function()
    local tm = t.new(5000)
    assert.is_truthy(tm)
    assert.are.equal(5000, tm.duration:asMilliseconds())
  end)

  it("inherits defaults from config", function()
    local tm = t.new(1000)
    assert.is_truthy(tm.title) -- config.default_timer has a title
  end)

  it("throws on invalid duration", function()
    assert.has_error(function()
      ---@diagnostic disable-next-line: param-type-mismatch
      t.new("bad")
    end, "Timer.new: duration must be a number or Duration")
  end)
end)

describe("Timer:paused", function()
  it("returns false when paused_at is nil", function()
    local tm = t.new(1000)
    tm.started_at = os.time()
    assert.is_false(tm:paused())
  end)

  it("returns true when paused_at is set", function()
    local tm = t.new(1000)
    tm.started_at = os.time()
    tm.paused_at = os.time()
    assert.is_true(tm:paused())
  end)
end)

describe("Timer:expire_in", function()
  it("calculates remaining time while running", function()
    local tm = t.new(5 * u.SECOND)
    tm.started_at = os.time()

    local fake_now = tm.started_at + 2
    stub(os, "time", function()
      return fake_now
    end)

    local d = tm:expire_in()
    assert.is_true(d:asMilliseconds() <= 3000 and d:asMilliseconds() >= 2000)

    os.time:revert()
  end)

  it("calculates remaining time while paused", function()
    local tm = t.new(5 * u.SECOND)
    tm.started_at = os.time()
    tm.paused_at = tm.started_at + 2

    local d = tm:expire_in()
    assert.are.equal(3000, d:asMilliseconds())
  end)
end)
