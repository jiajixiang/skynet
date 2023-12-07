local skynet = require "skynet"
local protobuf = require "protobuf"
local netpack = require "skynet.netpack"
local cluster = require "skynet.cluster"
local string = require "string"
local socket = require "skynet.socket"
require "common.base.init"

local nodeId = skynet.getenv("id")
local gateMgr
local host
local send_request
local CMD = {}
local REQUEST = {}
local client_fd

function REQUEST:get()
	local r = skynet.call("SIMPLEDB", "lua", "get", self.what)
	return { result = r }
end

function REQUEST:set()
	local r = skynet.call("SIMPLEDB", "lua", "set", self.what, self.value)
end

function REQUEST:handshake()
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

function REQUEST:quit()
	skynet.call(gateMgr, "lua", "close", client_fd)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
    unpack = skynet.tostring,
	dispatch = function(session, address, msg, ...)
		assert(session == client_fd)
		skynet.ignoreret()	-- session is fd, don't call skynet.ret
		local cmd,args,typ,session = skynet.call(".protoLoader", "lua", "decode", msg)
		skynet.send(".main", "lua", "internal", "c2sMessageRedirect",  client_fd, cmd, args)
	end,
}

function CMD.start(conf)
	local fd = conf.client
	local gate = conf.gate
	gateMgr = conf.watchdog

	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.exit()
end

function CMD.sendToClient(cmd, args)
	local typ = 1
	local session = 1
	local pack = skynet.call(".protoLoader", "lua", "encode", cmd, args, typ, session)
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
end

skynet.init(function()

end)

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = CMD[cmd]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
