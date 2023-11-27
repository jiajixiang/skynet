local cluster = require "cluster"
local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register
local command = {}
local nodes = {}

AllProxyDict = {
    --[[ 
        [nodeId] = {
            [serviceName] = proxy
    }
    ]]--
}

local function getProxy(nodeId, serviceName)
    local proxy = AllProxyDict[nodeId] and AllProxyDict[nodeId][serviceName]
    if not proxy then
        proxy = ClusterProxy.new(nodeId, serviceName)
        if not AllProxyDict[nodeId] then
            AllProxyDict[nodeId] = {}
        end
        AllProxyDict[nodeId][serviceName] = proxy
    end
    return proxy
end

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

local function init()
    initNotes()
    local cluster_port = tonumber(skynet.getenv("cluster_port"))
    cluster.open(cluster_port)
    cluster.reload(nodes)
    return true
end

function command.SEND(nodeId, serviceName, ...)
	local proxy = getProxy(nodeId, serviceName)
	return proxy:send(...)
end

function command.CALL(nodeId, serviceName, ...)
	local proxy = getProxy(nodeId, serviceName)
	return proxy:call(...)
end

function command.REGISTER(serviceName)
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

skynet.init(function()
    require "common.base.init"
end)

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		cmd = cmd:upper()
		if cmd == "PING" then
			assert(session == 0)
			local str = (...)
			if #str > 20 then
				str = str:sub(1,20) .. "...(" .. #str .. ")"
			end
			skynet.error(string.format("%s ping %s", skynet.address(address), str))
			return
		end
		local f = command[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	skynet.register(".nodeMgr")
    init()
--	skynet.traceproto("lua", false)	-- true off tracelog
end)
