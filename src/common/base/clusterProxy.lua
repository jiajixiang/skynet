local queue = require "skynet.queue"
local skynet = require "skynet"

local ClusterProxy = class("ClusterProxy")

function ClusterProxy:ctor()
    self.nodeMgr = skynet.localname(".nodeMgr")
end

function ClusterProxy:send(nodeName, serviceName, ...)
    local addr = skynet.localname(serviceName)
    if addr then
        return skynet.send(addr, "lua", ...)
    end
    return skynet.send(self.nodeMgr, "lua", "send", nodeName, serviceName, ...)
end

function ClusterProxy:call(nodeName, serviceName, ...)
    local addr = skynet.localname(serviceName)
    if addr then
        return skynet.call(addr, "lua", ...)
    end
    return skynet.call(self.nodeMgr, "lua", "call", nodeName, serviceName, ...)
end

function ClusterProxy:register(serviceName)
    return skynet.send(self.nodeMgr, "lua", "register", serviceName)
end

function ClusterProxy:reload()
    return skynet.call(self.nodeMgr, "lua", "reload")
end

function ClusterProxy:open()
    return skynet.send(self.nodeMgr, "lua", "open")
end

return ClusterProxy