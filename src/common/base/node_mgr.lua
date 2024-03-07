local cluster = require "cluster"
local skynet = require "skynet"
require "skynet.manager"
local nodes = {}

function register(serviceName)
    local serverId = skynet.getenv("serverId")
    local cluster_port = tonumber(skynet.getenv("cluster_port"))
    local nodeId = skynet.getenv("id")
    local db = MONGO.getDb("nodes")
    local cursor = db.nodes:find({
        serverId = serverId
    })
    while cursor:hasNext() do
        local data = cursor:next()
        if data.cluster_port then
            nodes[data.nodeId] = data.ip .. ":" .. data.cluster_port
        end
    end
    local data = {
        nodeId = nodeId,
        serverId = serverId,
        ip = skynet.getenv("ip"),
        cluster_port = cluster_port
    }
    db.nodes:update({
        nodeId = nodeId,
        serverId = serverId
    }, data, true, false)
    nodes[data.nodeId] = data.ip .. ":" .. data.cluster_port
    local addr = skynet.localname(serviceName)
    cluster.open(cluster_port)
    cluster.register(serviceName, addr)
    cluster.reload(nodes)
    print("cluster.reload:", table.dump(nodes))
    return true
end

function __init__(...)

end
