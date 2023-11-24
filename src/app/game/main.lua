local skynet = require "skynet"

skynet.init(function()
    require "common.init"
    require "app.game.init"
end)

skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, ...)

    end)

	print("game service start")
    local nodeName = "game"
    local serviceName = ".game"
    skynet.name(serviceName, skynet.self())
    if skynet.getenv("id") == nodeName then
        skynet.newservice("debug_console",8000)
    end
    -- cluster = ClusterRpc.new(serviceName)
    -- cluster:start()
    if skynet.getenv("cluster_prot") then
        local cluster = skynet.newservice("clusterRpc")
        skynet.name(".cluster", cluster)
    end
    local cluster = skynet.localname(".cluster")
    local ret = skynet.call(cluster, "lua", "register", serviceName)
    print(ret)
    local ret = skynet.call(cluster, "lua", "reload")
    print(table.dump(ret))
    local ret = skynet.call(cluster, "lua", "open")
    print(ret)
    local ret = skynet.call(cluster, "lua", "send", "login", ".login", "set", "-------")
    print(ret)
	-- skynet.newservice("db")
	-- skynet.newservice("gate")
	-- skynet.newservice("login")
	-- skynet.newservice("agent")
	print("game service exit")
end)