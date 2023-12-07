local queue = require "skynet.queue"
local skynet = require "skynet"
local cluster = require "cluster"

local AllProxyTbl = {}

local GateProxy = class("GateProxy", Proxy)

function GateProxy:ctor()
    local serviceId = ".gate"
    local addr = skynet.localname(serviceId)
    if addr then
        self.internal = addr
        self.nodeId = skynet.getenv("id")
        self.proxy = Proxy.new(self.nodeId, serviceId)
    else
        self.nodeId = "gate"
        self.proxy = Proxy.new(self.nodeId, ".main")
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

function protoRedirectRegiste( ... )
    local proxy = _allocProxy()
    proxy:send("internal", "protoRedirectRegiste", ...)
end

function s2cMessageToClient( ... )
    local proxy = _allocProxy()
    proxy:send("internal", "s2cMessageToClient", ...)
end
