local queue = require "skynet.queue"
local skynet = require "skynet"

local ClusterAgent = class("ClusterAgent")

function ClusterAgent:ctor(serviceName)
    self.nodeId = skynet.getenv("id")
    self.address = skynet.getenv("cluster_address")
    self.serviceName = serviceName
end

function ClusterAgent:start()
    local nodeId = self.nodeId
    local db = Mongo.getdb()
    local data = db.nodes:findOne({nodeId = nodeId}) or {}
    if not data.services then
        data.services = {}
    end
    local services = data.services
    local serviceName = self.serviceName
    local addr = skynet.address(skynet.self())
    services[serviceName] = addr
    db.nodes:update({nodeId = nodeId}, {
        nodeId = nodeId,
        services = services,
        address = self.address,
    }, true, false)
end

function ClusterAgent:onLoad()
end

function ClusterAgent:open()
end

return ClusterAgent