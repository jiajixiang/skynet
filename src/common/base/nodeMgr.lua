local cluster = require "cluster"
local skynet = require "skynet"
require "skynet.manager"
local nodes = {}

local function initNotes()
    local db = Mongo.getdb()
    local serverId = skynet.getenv("serverId")
    local cursor = db.nodes:find({serverId = serverId})
    while cursor:hasNext() do
        local data = cursor:next()
        if data.cluster_port then
            nodes[data.nodeId] = data.ip..":"..data.cluster_port
        end
    end
end

function register(serviceName)
    local addr = skynet.localname(serviceName)
    local nodeId = skynet.getenv("id")
    local serverId = skynet.getenv("serverId")
    local db = Mongo.getdb()
    local data = db.nodes:findOne({nodeId = nodeId, serverId = serverId})
    if not data then
        data = {
            serverId = serverId,
            nodeId = nodeId,
            services = {},
        }
    end
    data.serverId = serverId
    data.ip = skynet.getenv("ip")
    data.port = skynet.getenv("port")
    data.cluster_port = skynet.getenv("cluster_port")
    data.services[serviceName] = addr
    db.nodes:update({nodeId = nodeId, serverId = serverId}, data, true, false)
    nodes[data.nodeId] = data.ip..":"..data.cluster_port
    cluster.register(serviceName, addr)
    return true
end

function init()
    initNotes()
    local cluster_port = tonumber(skynet.getenv("cluster_port"))
    cluster.open(cluster_port)
    cluster.reload(nodes)
    print(table.dump(nodes))
    return true
end