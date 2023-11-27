local skynet = require "skynet"

skynet.init(function()
    require "common.init"
    require "app.login.init"
end)

skynet.start(function()
    skynet.dispatch("lua", function (session, address, cmd, ...)
        print(session, address, cmd, ...)
        return true
	end)

	print("login service start")
    local nodeId = "login"
    local serviceId = ".login"
    skynet.name(serviceId, skynet.self())
    if skynet.getenv("id") == nodeId then
        skynet.newservice("debug_console",8000)
    end
    if skynet.getenv("cluster_port") then
        skynet.uniqueservice(true, "nodeMgr")
    end
    -- skynet.newservice("login")
    if skynet.getenv("cluster_port") then
        skynet.uniqueservice(true, "nodeMgr")
    end
    clusterMgr = ClusterMgr.new()
    clusterMgr:register(serviceId)
	print("login service exit")
end)