local skynet = require "skynet"
local protobuf = require "protobuf"
local netpack = require "skynet.netpack"
local string = require "string"
local socket = require "skynet.socket"
require "common.base.init"

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

local function request(name, args, response)
	local f = assert(REQUEST[name])
	local r = f(args)
	if response then
		return response(r)
	end
end

local function send_package(pack)
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
end

local function endunpack_message(msg, sz)
    local typ,session,message_id = string.unpack("<I1I4I2",msg)
    local args_bin = msg:sub(8)
    -- self.proto[message_id]
    local cmd = "C2S_Login"
    local args,err = protobuf.decode(cmd,args_bin)
    assert(err == nil,err)
    if typ == 1 then
        assert(session ~= 0,"session not found")
    end
    return cmd,args,typ,session
end

local function pack_message(cmd,args,typ,session)
    local message_id = 1
    typ = typ or 0
    session = session or 0
    local result = string.pack("<I1I4I2",typ,session,message_id)
    if args then
        local args_bin = protobuf.encode(cmd,args)
        result = result .. args_bin
    end
    return result
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
    unpack = skynet.tostring,
	dispatch = function(session, address, msg, ...)
		local cmd,args,typ,session = skynet.call(".protoloader", "lua", "decode", msg)
		print(debug.traceback())
        print("client", session, address, msg, ...)
		skynet.ret(skynet.pack(true))
	end,
}

function CMD.start(conf)
	local fd = conf.client
	local gate = conf.gate
	gateMgr = conf.gateMgr

	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
        print("agent", session, address, cmd, ...)
		-- skynet.trace()
		local f = CMD[cmd]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
