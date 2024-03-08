local cluster = require "cluster"
local skynet = require "skynet"
require "skynet.manager"
local nodes = {}
local cluster_nodes = {}

local function initNodes()
    local serverId = skynet.getenv("serverId")
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
end

function startNode()
    local selfNodeId = skynet.getenv("id")
    local serverId = skynet.getenv("serverId")
    local cluster_port = tonumber(skynet.getenv("cluster_port"))
    local data = {
        nodeId = selfNodeId,
        serverId = serverId,
        ip = skynet.getenv("ip"),
        cluster_port = cluster_port,
        status = true,
    }
    nodes[data.nodeId] = data

    local db = MONGO.getDb("nodes")
    db.nodes:update({
        nodeId = selfNodeId,
        serverId = serverId
    }, data, true, false)
    cluster_nodes[data.nodeId] = data.ip .. ":" .. data.cluster_port

    local addr = skynet.localname(".main")
    cluster.open(cluster_port)
    cluster.register(".main", addr)
    cluster.reload(cluster_nodes)
    print("cluster.reload:", table.dump(nodes))
    for nodeId, nodeData in pairs(nodes) do
        if nodeId ~= selfNodeId and nodeData.status then
            local proxyObj = PROXY.tryGetProxy(nodeId, ".main")
            proxyObj:send("internal", "onNodeStart", data)
        end
    end
end

function stopNode()
    local selfNodeId = skynet.getenv("id")
    local serverId = skynet.getenv("serverId")
    local data = nodes[selfNodeId]
    data.status = false
    local db = MONGO.getDb("nodes")
    db.nodes:update({
        nodeId = selfNodeId,
        serverId = serverId
    }, data, true, false)

    for nodeId, nodeData in pairs(nodes) do
        if nodeId ~= selfNodeId and nodeData.status then
            local proxyObj = PROXY.tryGetProxy(nodeId, ".main")
            proxyObj:send("internal", "onNodeStop", selfNodeId)
        end
    end
    skynet.abort()
end

function afterInitModule()
    initNodes()
end

function systemStartup()
    initNodes()
end

local function onNodeStart(data)
    nodes[data.nodeId] = data
    print("onNodeStart", data.nodeId)
end

local function onNodeStop(nodeId)
    nodes[nodeId].status = false
    print("onNodeStop", nodeId)
end

function __init__(...)
    for_internal.onNodeStart = onNodeStart
    for_internal.onNodeStop = onNodeStop
end
