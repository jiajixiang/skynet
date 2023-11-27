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
    local nodeName = "game"
    local serviceName = ".game"
    skynet.name(serviceName, skynet.self())
    if skynet.getenv("id") == nodeName then
        skynet.newservice("debug_console",8000)
    end
    if skynet.getenv("cluster_prot") then
        local cluster = skynet.newservice("clusterRpc")
        skynet.name(".cluster", cluster)
    end
    clusterProxy = ClusterProxy.new()
    clusterProxy:register(serviceName)
    local ret = clusterProxy:reload()
    print(table.dump(ret))
    clusterProxy:open()
    clusterProxy:send("login", ".login", "set", "-------")
	print("game service exit")
end)