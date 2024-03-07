local skynet = require "skynet"
local cluster = require "cluster"
local gate
local agent = {}
local proxyTbl = {}
local protoRedirect = {}

function for_socket.open(fd, addr)
	skynet.error("New client from : " .. addr)
    if not agent[fd] then
	    agent[fd] = skynet.newservice("agent")
    end
	skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self()})
end

local function close_agent(fd)
	local a = agent[fd]
	agent[fd] = nil
	if a then
		skynet.call(gate, "lua", "kick", fd)
		-- disconnect never return
		skynet.send(a, "lua", "disconnect")
	end
end

function for_socket.close(fd)
	close_agent(fd)
end

function for_socket.error(fd, msg)
	close_agent(fd)
end

function for_socket.warning(fd, size)
	print("socket warning", fd, size)
end

function for_socket.data(fd, msg, sz)
	print("socket data",fd, msg, sz)
    -- local cmd,args,typ,session = PROTO_LOADER.decode(skynet.tostring(msg, sz))
    -- print(cmd, args)
end

function for_cmd.start(conf)
	return skynet.call(gate, "lua", "open" , conf)
end

function for_cmd.close(fd)
	close_agent(fd)
end

function start( ... )
	gate = skynet.newservice("gate")
    skynet.call(gate, "lua", "open" , {
		port = tonumber(skynet.getenv("port")),
		maxclient = 64,
		servername = "gate",
	})
end

local function _getProxy(nodeId)
	local proxyObj = PROXY.getProxy(nodeId, ".main")
	if not proxyObj then
		
	end
	return proxyObj
end

local function onProtoRedirectRegiste(tbl, nodeId)
	assert(nodeId)
	for key, value in pairs(tbl) do
		protoRedirect[value] = nodeId
	end
end

local function onC2SMessageRedirect(fd, cmd, args)
	local nodeId = protoRedirect[cmd]
	assert(nodeId)
	local proxy = _getProxy(nodeId)
	proxy:send("client", cmd, fd, args)
end

local function onS2CMessageToClient(fd, cmd, args)
	local agent = agent[fd]
	if not agent then
		return
	end
	skynet.call(agent, "lua", "sendToClient", cmd, args)
end

function __init__()
    for_internal.protoRedirectRegiste = onProtoRedirectRegiste
	for_internal.c2sMessageRedirect = onC2SMessageRedirect
	for_internal.s2cMessageToClient = onS2CMessageToClient
end