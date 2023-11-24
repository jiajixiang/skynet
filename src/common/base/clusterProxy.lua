local queue = require "skynet.queue"
local skynet = require "skynet"

local ClusterProxy = class("ClusterProxy")

function ClusterProxy:ctor()
    self.cluster = skynet.localname(".cluster")
end

function ClusterProxy:send(...)
    return skynet.send(self.cluster, "lua", "send", ...)
end

function ClusterProxy:call(...)
    return skynet.call(self.cluster, "lua", "call", ...)
end

function ClusterProxy:register(serviceName)
    return skynet.send(self.cluster, "lua", "register", serviceName)
end

function ClusterProxy:reload()
    return skynet.call(self.cluster, "lua", "reload")
end

function ClusterProxy:open()
    return skynet.send(self.cluster, "lua", "open")
end

return ClusterProxy