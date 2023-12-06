local queue = require "skynet.queue"
local skynet = require "skynet"
local cluster = require "cluster"

local AllProxyTbl = {}

local GateProxy = class("GateProxy", Proxy)

function GateProxy:ctor()
    local serviceId = ".gateMgr"
    local addr = skynet.localname(serviceId)
    if addr then
        self.internal = addr
        self.nodeId = skynet.getenv("id")
    else
        self.nodeId = "gate"
        self.proxy = Proxy.new(self.nodeId, serviceId)
    end
end

function GateProxy:send(...)
    if self.internal then
        return skynet.send(self.internal, "lua", ...)
    end
    return self.proxy:send(...)
end

function GateProxy:call(...)
    if self.internal then
        return skynet.call(self.internal, "lua", ...)
    end
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