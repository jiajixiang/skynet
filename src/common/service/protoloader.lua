
local pb = require "protobuf"
local skynet = require "skynet"
local retTbl = {}
pb.register_file("../protobuf/all.pb")

--protobuf编码解码
function test4()
    pb.register_file("../protobuf/all.pb")
    --编码
    local msg = {
        id = 101,
        pw = "123456",
    }
    local buff = pb.encode("C2S_Login", msg)
    print("len:"..string.len(buff))
    --解码
    local umsg = pb.decode("C2S_Login", buff)
    if umsg then
        print("id:"..umsg.id)
        print("pw:"..umsg.pw)
    else
        print("error")
    end
end

local command = {}
function command.reg(cmdId, serviceName)

end

function command.getRegTbl()

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
end)