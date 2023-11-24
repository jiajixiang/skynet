local queue = require "skynet.queue"
local skynet = require "skynet"

local ClusterProxy = class("ClusterProxy")

function ClusterProxy:ctor(serviceName)
end

function ClusterProxy:start()
    local db = Mongo.getdb()
    self.nodes = {}
    local cursor = db.nodes:find()
    while cursor:hasNext() do
        local data = cursor:next()
        self.nodes[data.nodeId] = data.address
    end
end

function ClusterProxy:onLoad()
end

function ClusterProxy:open()
end

return ClusterProxy