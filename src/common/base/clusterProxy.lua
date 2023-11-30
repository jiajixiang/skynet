local queue = require "skynet.queue"
local skynet = require "skynet"
local cluster = require "cluster"
local ClusterProxy = class("ClusterProxy")

function ClusterProxy:ctor(nodeName, serviceName)
    self.nodeName = nodeName
    self.serviceName = serviceName
    self.proxy = cluster.proxy(nodeName, "@"..serviceName)
end

function ClusterProxy:send(...)
    if skynet.getenv("id") == self.nodeName then
        local addr = skynet.localname(self.serviceName)
        return skynet.send(addr, "lua", ...)
    end
	return skynet.send(self.proxy, "lua", ...)
end

function ClusterProxy:call(...)
    if skynet.getenv("id") == self.nodeName then
        local addr = skynet.localname(self.serviceName)
        return skynet.call(addr, "lua", ...)
    end
	return skynet.call(self.proxy, "lua", ...)
end

return ClusterProxy