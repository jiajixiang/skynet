local skynet = require "skynet"

skynet.init(function()
    require "common.init"
    require "app.agent.init"
end)

skynet.start(function()
	print("agent service start")
    local nodeId = "agent"
    local serviceId = ".main"
    skynet.name(serviceId, skynet.self())
    if skynet.getenv("id") == nodeId then
        skynet.newservice("debug_console",8000)
    end
    skynet.uniqueservice("agentMgr")
    if skynet.getenv("cluster_port") then
        skynet.uniqueservice("nodeMgr")
    end
    clusterMgr = ClusterMgr.new()
    clusterMgr:register(serviceId)
    --clusterMgr:send("login", ".login", "lua", "set", "-------")
	print("agent service exit")
end)