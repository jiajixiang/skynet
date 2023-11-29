
local protobuf = require "protobuf"
local skynet = require "skynet"
require "skynet.manager"
local retTbl = {}
require "common.init"
protobuf.register_file("../protobuf/all.pb")
local protoId2Cmd = {}
local proto = loadfile("../protobuf/proto.lua")()
--protobuf编码解码
function test4()
    --编码
    local msg = {
        id = 101,
        pw = "123456",
    }
    local buff = protobuf.encode("C2S_Login", msg)
    print("len:"..string.len(buff))
    --解码
    local umsg = protobuf.decode("C2S_Login", buff)
    if umsg then
        print("id:"..umsg.id)
        print("pw:"..umsg.pw)
    else
        print("error")
    end
end

local function initProto()
    for cmd, messageId in pairs(proto) do
        protoId2Cmd[messageId] = cmd
    end
end

local command = {}

function command.decode(msg)
    local typ,session,message_id = string.unpack("<I1I4I2",msg)
    local args_bin = msg:sub(8)
    -- self.proto[message_id]
    local cmd = protoId2Cmd[message_id]
    local args,err = protobuf.decode(cmd,args_bin)
    assert(err == nil,err)
    if typ == 1 then
        assert(session ~= 0,"session not found")
    end
    return cmd,args,typ,session
end

function command.encode(cmd,args,typ,session)
    local message_id = proto[cmd]
    typ = typ or 0
    session = session or 0
    local result = string.pack("<I1I4I2",typ,session,message_id)
    if args then
        local args_bin = protobuf.encode(cmd,args)
        result = result .. args_bin
    end
    return result
end

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = command[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
    local serviceId = ".protoloader"
	skynet.register(serviceId)
    clusterMgr = ClusterMgr.new()
    clusterMgr:register(serviceId)
    initProto()
end)