local skynet = require "skynet"
local cluster = require "cluster"
local CMD = {}
local SOCKET = {}
local gate
local agent = {}

function SOCKET.open(fd, addr)
	skynet.error("New client from : " .. addr)
    if not agent[fd] then
	    agent[fd] = skynet.newservice("agent")
    end
	skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self() })
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

function SOCKET.close(fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	print("socket warning", fd, size)
end

function SOCKET.data(fd, msg, sz)
	print("socket data",fd, msg, sz)
end

function CMD.start(conf)
	return skynet.call(gate, "lua", "open" , conf)
end

function CMD.close(fd)
	close_agent(fd)
end

skynet.init(function ()
    require "common.init"
	NODE_MGR = Import("common/base/nodeMgr.lua")
	PROTO_CATALOG_MGR = Import("common/base/protoCatalogMgr.lua")
end)

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)
    local serviceId = ".gateMgr"
	skynet.register(serviceId)
	NODE_MGR.register(serviceId)
	gate = skynet.newservice("gate")
    skynet.call(gate, "lua", "open" , {
		port = tonumber(skynet.getenv("port")),
		maxclient = 64,
		servername = "gate",
	})
end)
