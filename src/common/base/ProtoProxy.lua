local skynet = require "skynet"

local AllProxyTbl = {}

local ProtoProxy = class("ProtoProxy", Proxy)

function ProtoProxy:ctor(nodeId)
    local serviceId = ".protoLoader"
    local addr = skynet.localname(serviceId)
    if addr then
        self.internal = addr
        self.nodeId = skynet.getenv("id")
    else
        self.nodeId = "gate"
        self.proxy = Proxy.new(self.nodeId, serviceId)
    end
end

function ProtoProxy:send(...)
    if self.internal then
        return skynet.send(self.internal, "lua", ...)
    end
    return self.proxy:send(...)
end

function ProtoProxy:call(...)
    if self.internal then
        return skynet.send(self.internal, "lua", ...)
    end
    return self.proxy:send(...)
end

local function _allocProxy()
    if not next(AllProxyTbl) then
        AllProxyTbl[#AllProxyTbl + 1] = ProtoProxy.new()
    end
    return AllProxyTbl[math.random(1, #AllProxyTbl)]
end

function register(...)
    local proxy = _allocProxy()
    proxy:send("register", ...)
end

return ProtoProxy