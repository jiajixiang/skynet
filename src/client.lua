package.cpath = "../tools/skynet/luaclib/?.so"
package.path = "../tools/skynet/lualib/?.lua"
local socket = require "client.socket"
local pb = require "protobuf"

local function endunpack_message(msg)
    local typ,session,message_id = string.unpack("<I1I4I2",msg)
    local args_bin = msg:sub(8)
    -- self.proto[message_id]
    local cmd = assert(1, message_id)
    local args,err = protobuf.decode(cmd,args_bin)
    assert(err == nil,err)
    if typ == 1 then
        assert(session ~= 0,"session not found")
    end
    return cmd,args,typ,session
end

local function pack_message(cmd,args,typ,session)
    local message_id = assert(1,cmd)
    if type(cmd) == "number" then
        local id = cmd
        cmd = message_id
        message_id = id
    end
    typ = typ or 0
    session = session or 0
    local result = string.pack("<I1I4I2",typ,session,message_id)
    if args then
        local args_bin = protobuf.encode(cmd,args)
        result = result .. args_bin
    end
    return result
end

fd = assert(socket.connect("127.0.0.1", 32001))
    pb.register_file("../tools/protobuf/all.pb")
    --编码
    local args = {
        id = 101,
        pw = "123456",
    }
    local buff = pack_message("C2S_Login",args, 1, 1)
    print("len:"..string.len(buff))
	socket.send(fd, buff)