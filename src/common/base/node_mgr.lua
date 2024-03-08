local cluster = require "cluster"
local skynet = require "skynet"
require "skynet.manager"
local nodes = {}
local cluster_nodes = {}
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
            data._id = nil
            nodes[data.nodeId] = data
            cluster_nodes[data.nodeId] = data.ip .. ":" .. data.cluster_port
        end
    end
    local data = {
        nodeId = nodeId,
        serverId = serverId,
        ip = skynet.getenv("ip"),
        cluster_port = cluster_port,
        status = true,
    }
    nodes[data.nodeId] = data
    db.nodes:update({
        nodeId = nodeId,
        serverId = serverId
    }, data, true, false)
    cluster_nodes[data.nodeId] = data.ip .. ":" .. data.cluster_port
    local addr = skynet.localname(serviceName)
    cluster.open(cluster_port)
    cluster.register(serviceName, addr)
    cluster.reload(cluster_nodes)

    for nodeId, nodeData in pairs(nodes) do
        if nodeId ~= data.nodeId and nodeData.status then
            local proxyObj = PROXY.getProxy(nodeId, ".main")
            local oci = {
                _nodeName = nodeId,
                _serviceName = ".main"
            }
            local proxyObj = PROXY.clsProxy:New(oci)
            proxyObj:send("internal", "onNodeStart", data.nodeId)
        end
    end
    print("cluster.reload:", table.dump(nodes))
    return true
end

local function onNodeStart(nodeId)
    print("onNodeStart", nodeId)
end

function __init__(...)
    for_internal.onNodeStart = onNodeStart
end
