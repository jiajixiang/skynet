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
    if skynet.getenv("cluster_prot") then
        skynet.uniqueservice(true, "nodeMgr")
    end
    clusterProxy = ClusterProxy.new()
    clusterProxy:register(serviceName)
    local ret = clusterProxy:reload()
    print(table.dump(ret))
    if skynet.getenv("id") == nodeName then
        clusterProxy:open()
    end
    -- local ret = skynet.call(cluster, "lua", "send", "login", ".login", "set", "-------")
    -- print(ret)
	print("login service exit")
end)