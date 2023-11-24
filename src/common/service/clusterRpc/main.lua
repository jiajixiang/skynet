local cluster = require "cluster"
local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register
local command = {}
local nodes = {}

function command.SEND(nodeId, serviceName, ...)
	local proxy = cluster.proxy(nodeId, "@"..serviceName)
	skynet.send(proxy, "lua", ...)
    return true
end

function command.CALL(nodeId, serviceName, ...)
    local proxy = cluster.proxy(nodeId, "@"..serviceName)
	return skynet.call(proxy, "lua", ...)
end

local function initNotes()
    local db = Mongo.getdb()
    local cursor = db.nodes:find()
    while cursor:hasNext() do
        local data = cursor:next()
        nodes[data.nodeId] = data.ip..":"..data.cluster_prot
    end
end

function command.OPEN()
    local cluster_prot = tonumber(skynet.getenv("cluster_prot"))
    cluster.open(cluster_prot)
    return true
end

function command.REGISTER(serviceName)
    local addr = skynet.localname(serviceName)
    local nodeId = skynet.getenv("id")
    local db = Mongo.getdb()
    local data = db.nodes:findOne({nodeId = nodeId})
    if not data then
        data = {
            nodeId = nodeId,
            services = {},
        }
    end
    data.ip = skynet.getenv("ip")
    data.port = skynet.getenv("port")
    data.cluster_prot = skynet.getenv("cluster_prot")
    data.services[serviceName] = addr
    db.nodes:update({nodeId = nodeId}, data, true, false)
    cluster.register(serviceName, addr)
    initNotes()
    return true
end

function command.RELOAD()
    cluster.reload(nodes)
    return nodes
end

skynet.register_protocol {
	name = "cluster",
	id = skynet.PTYPE_SYSTEM,
    pack = function (...)
        return ...
    end,
	unpack = function(...) 
        return ... 
    end,
	dispatch = function()
		-- reopen signal
		print("SIGHUP")
	end
}

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
	skynet.register(".cluster")
    initNotes()
--	skynet.traceproto("lua", false)	-- true off tracelog
end)
