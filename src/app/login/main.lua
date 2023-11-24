local skynet = require "skynet"

skynet.init(function()
    require "common.init"
    require "app.login.init"
end)

skynet.start(function()
    skynet.dispatch("lua", function (session, address, cmd, ...)
        print(session, address, cmd, ...)
	end)

	print("login service start")
    local nodeName = "login"
    local serviceName = ".login"
    skynet.name(serviceName, skynet.self())
    if skynet.getenv("id") == nodeName then
        skynet.newservice("debug_console",8000)
    end
    -- cluster = ClusterRpc.new(serviceName)
    -- cluster:start()
    if skynet.getenv("cluster_prot") then
        skynet.newservice("clusterRpc")
    end
    local cluster = skynet.localname(".cluster")
    local ret = skynet.call(cluster, "lua", "register", serviceName)
    print(ret)
    local ret = skynet.call(cluster, "lua", "reload")
    print(table.dump(ret))
    local ret = skynet.call(cluster, "lua", "open")
    print(ret)
    -- local ret = skynet.call(cluster, "lua", "send", "login", ".login", "set", "-------")
    -- print(ret)
	print("login service exit")
end)