local skynet = require "skynet"
local pb = require "protobuf"

skynet.init(function()
    require "common.init"
    require "app.gate.init"
end)

skynet.start(function()
    skynet.dispatch("lua", function (session, address, cmd, ...)
        print(session, address, cmd, ...)
	end)

	print("gate service start")
    local nodeId = "gate"
    local serviceId = ".gate"
    skynet.name(serviceId, skynet.self())
    if skynet.getenv("id") == nodeId then
        skynet.newservice("debug_console",8000)
    end
    if skynet.getenv("cluster_port") then
        skynet.uniqueservice(true, "nodeMgr")
    end
    skynet.uniqueservice("protoloader")
    clusterMgr = ClusterMgr.new()
    clusterMgr:register(serviceId)
    local gateMgr = skynet.newservice("gateMgr")
	print("gate service exit")
end)