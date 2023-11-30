local queue = require "skynet.queue"
local skynet = require "skynet"

local ClusterMgr = class("ClusterMgr")

function ClusterMgr:ctor()
    self.nodeMgr = skynet.localname(".nodeMgr")
end

function ClusterMgr:send(nodeId, serviceName, ...)
    if skynet.getenv("id") == nodeId then
        return skynet.send(addr, "lua", ...)
    end
	return skynet.send(self.nodeMgr, "lua", "send", nodeId, serviceName, ...)
end

function ClusterMgr:call(nodeId, serviceName, ...)
    if skynet.getenv("id") == nodeId then
        local addr = skynet.localname(serviceName)
        return skynet.call(addr, "lua", ...)
    end
	return skynet.call(self.nodeMgr, "lua", "call", nodeId, serviceName, ...)
end

function ClusterMgr:register(serviceName)
    return skynet.call(self.nodeMgr, "lua", "register", serviceName)
end

return ClusterMgr