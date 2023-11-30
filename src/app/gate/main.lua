local skynet = require "skynet"
local pb = require "protobuf"

Rpc = {}
Client = {}

skynet.init(function()
    require "common.init"
    require "app.gate.init"
end)

skynet.start(function()
    skynet.dispatch("lua", function (session, address, cmd, subCmd, ...)
        if cmd == "client" then
            local func = Client[subCmd]
			skynet.ret(skynet.pack(func(...)))
        elseif cmd == "cluster" then
            local func = Rpc[subCmd]
			skynet.ret(skynet.pack(func(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
    end)

	print("gate service start")
    local nodeId = "gate"
    local serviceId = ".main"
    skynet.name(serviceId, skynet.self())
    if skynet.getenv("cluster_port") then
        skynet.uniqueservice(true, "nodeMgr")
    end
    if skynet.getenv("id") == nodeId then
        skynet.newservice("debug_console",8000)
    end
    clusterMgr = ClusterMgr.new()
    clusterMgr:register(serviceId)
    skynet.uniqueservice("protoloader")
    gateMgr = skynet.newservice("gateMgr")
	print("gate service exit")
end)