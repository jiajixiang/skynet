local queue = require "skynet.queue"
local skynet = require "skynet"

local ClusterProxy = class("ClusterProxy")

function ClusterProxy:ctor()
    self.nodeMgr = skynet.localname(".nodeMgr")
end

function ClusterProxy:send(...)
    return skynet.send(self.nodeMgr, "lua", "send", ...)
end

function ClusterProxy:call(...)
    return skynet.call(self.nodeMgr, "lua", "call", ...)
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