local skynet = require "skynet"

local Timer = {}

local Timer = class("Timer")
function Timer:ctor(interval)
    if not interval then
        interval = 100
    end

    self.inc = 0

    self.interval = interval

    self.timer_idx = 0

    self.callbacks = {}

    self.timer_idxs = {}

    skynet.timeout(self.interval, function()
        self:on_time_out()
    end)
end

function Timer.on_time_out(self)
    skynet.timeou(self.interval, function()
        self:on_time_out()
    end)

    self.inc = self.inc + 1

    local callbacks = self.callbacks[self.inc]

    if not callbacks then
        return
    end

    for idx, f in pairs(callbacks) do
        f()
        self.timer_idxs[idx] = nil
    end

    self.callbacks[self.inc] = nil
end

function Timer.register(self, sec, f, loop)
    assert(type(sec) == "number" and sec > 0)

    sec = self.inc + sec

    self.timer_idx = self.timer_idx + 1

    self.timer_idxs[self.timer_idx] = sec

    if not self.callbacks[sec] then
        self.callbacks[sec] = {}
    end

    local callbacks = self.callbacks[sec]

    if not loop then
        loop = false
    end

    callbacks[self.timer_idx] = f

    return self.timer_idx
end

function Timer.unregister(self, idx)
    local sec = self.timer_idxs[idx]

    if not sec then
        return
    end

    local callbacks = self.callbacks[sec]

    callbacks[idx] = nil

    self.timer_idxs[idx] = nil
end

return Timer
