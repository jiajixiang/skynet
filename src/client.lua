package.cpath = "../tools/skynet/luaclib/?.so"
package.path = "../tools/skynet/lualib/?.lua"
local socket = require "client.socket"
local protobuf = require "protobuf"
local socket = require "client.socket"
local crypt = require "client.crypt"
local table = table
function table.dump(t,depth,name)
    if type(t) ~= "table" then
        return tostring(t)
    end
    depth = depth or 0
    local max_depth = 5
    name = name or ""
    local cache = { [t] = "."}
    local function _dump(t,depth,name)
        local temp = {}
        local bracket_space = string.rep(" ",depth * 2)
        local space = string.rep(" ",(depth + 1) * 2)
        table.insert(temp,"{")
        if depth < max_depth then
            for k,v in pairs(t) do
                local key = tostring(k)
                if type(k) == "number" then
                    key = "[" .. key .. "]"
                end
                local value
                if cache[v] then
                    value = cache[v]
                elseif type(v) == "table" then
                    local new_key = name .. "." .. key
                    cache[v] = new_key
                    value = _dump(v,depth+1,new_key)
                else
                    if type(v) == "string" then
                        v = "\"" .. string.gsub(v,"\"","\\\"") .. "\""
                    end
                    value = tostring(v)
                end
                table.insert(temp,space .. key .. " = " .. value)
            end
        else
            table.insert(temp,space .. "...")
        end
        table.insert(temp,bracket_space .. "}")
        return table.concat(temp,"\n")
    end
    return _dump(t,depth,name)
end

local function endunpack_message(msg)
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

protobuf.register_file("../tools/protobuf/all.pb")
--编码
local args = {
    id = 101,
    pw = "123456",
}
local message = pack_message("C2S_Login", args, 1, 1)
print(message, type(message), string.len(message))
local cmd,args,typ,session = endunpack_message(message)
print(cmd,table.dump(args),typ,session)

local fd = assert(socket.connect("127.0.0.1", 32001))
socket.send(fd, message)
socket.usleep(100)