local client = Client
local skynet = require "skynet"

function client.Send_To_Client(...)
	skynet.call(gateMgr, "lua", "sendToClient", ...)
end