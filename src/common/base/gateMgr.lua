local skynet = require "skynet"
local cluster = require "cluster"
local gate
local agent = {}

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
    local cmd,args,typ,session = PROTO_LOADER.decode(skynet.tostring(msg, sz))
    print(cmd, args)
end

function for_cmd.start(conf)
	return skynet.call(gate, "lua", "open" , conf)
end

function for_cmd.close(fd)
	close_agent(fd)
end

function for_cmd.sendToClient(fd, cmd, args)
	local agent = agent[fd]
	if not agent then
		return
	end
	skynet.call(agent, "lua", "sendToClient", cmd, args)
end

function for_cmd.client2Game(fd, cmd, args)
	print(fd, cmd, args)
	-- body
end

function start( ... )
	gate = skynet.newservice("gate")
    skynet.call(gate, "lua", "open" , {
		port = tonumber(skynet.getenv("port")),
		maxclient = 64,
		servername = "gate",
	})
end

function __init__()
    -- body
end