local queue = require "skynet.queue"
local skynet = require "skynet"
local cluster = require "cluster"

local AllProxyTbl = {}

local ProtoProxy = class("ProtoProxy", Proxy)

function ProtoProxy:ctor(nodeId)
    if "login" == skynet.getenv("id") then
        self.nodeId = "login"
    else
        self.nodeId = "gate"
    end
    self.proxy = Proxy.new(self.nodeId, ".protoLoader")
end

function ProtoProxy:send(...)
    return self.proxy:send(...)
end

function ProtoProxy:call(...)
    return self.proxy:call(...)
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