
local protobuf = require "protobuf"
local skynet = require "skynet"
local sharetable = require "skynet.sharetable"
require "skynet.manager"
require "common.init"

local proto = {}
local protoFileName = "../protobuf/proto.lua"
protobuf.register_file("../protobuf/all.pb")
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
    for cmd, messageId in pairs(sharetable.query(protoFileName)) do
        proto[cmd] = messageId
        proto[messageId] = cmd
    end
end

function decode(msg)
    local typ,session,message_id = string.unpack("<I1I4I2",msg)
    local args_bin = msg:sub(8)
    local cmd = proto[message_id]
    local args,err = protobuf.decode(cmd,args_bin)
    assert(err == nil,err)
    if typ == 1 then
        assert(session ~= 0,"session not found")
    end
    return cmd,args,typ,session
end

function encode(cmd,args,typ,session)
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

local function init( ... )
    sharetable.loadfile(protoFileName, protoFileName)
    -- proto = sharetable.query("proto")
    initProto()
end

function __init__(...)
    init(...)
end