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
    local addr = skynet.localname(self.serviceName)
    if addr then
        return skynet.send(addr, ...)
    end
	return skynet.send(self.proxy, ...)
end

function ClusterProxy:call(...)
    local addr = skynet.localname(self.serviceName)
    if addr then
        return skynet.call(addr, ...)
    end
	return skynet.call(self.proxy, ...)
end

return ClusterProxy