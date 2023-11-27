local skynet = require "skynet"

skynet.init(function()
    require "common.init"
    require "app.game.init"
end)

skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, ...)
        print(session, address, cmd, ...)
    end)

	print("game service start")
    local nodeId = "game"
    local serviceId = ".game"
    skynet.name(serviceId, skynet.self())
    if skynet.getenv("id") == nodeId then
        skynet.newservice("debug_console",8000)
    end
    -- skynet.newservice("login")
    if skynet.getenv("cluster_prot") then
        skynet.uniqueservice(true, "nodeMgr")
    end
    clusterMgr = ClusterMgr.new()
    clusterMgr:register(serviceId)
    clusterMgr:send("login", ".login", "lua", "set", "-------")
    -- clusterMgr:call("login", ".login", "lua", "set", "-------")
	print("game service exit")
end)