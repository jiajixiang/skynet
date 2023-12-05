local queue = require "skynet.queue"
local skynet = require "skynet"
local cluster = require "cluster"

local AllProxyTbl = {}

local GateProxy = class("GateProxy", Proxy)

function GateProxy:ctor()
    self.nodeId = skynet.getenv("id")
    self.proxy = Proxy.new("gate", ".main")
end

function GateProxy:send(...)
    return self.proxy:send(...)
end

function GateProxy:call(...)
    return self.proxy:call(...)
end

local function _allocProxy()
    if not next(AllProxyTbl) then
        AllProxyTbl[#AllProxyTbl + 1] = GateProxy.new()
    end
    return AllProxyTbl[math.random(1, #AllProxyTbl)]
end

function sendToClient( ... )
    local proxy = _allocProxy()
    proxy:send("sendToClient", ...)
end

return GateProxy