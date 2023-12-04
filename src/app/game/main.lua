local skynet = require "skynet"
require "skynet.manager"   --除了需要引入skynet包以外还要再引入skynet.manager包。
Rpc = {}
Client = {}

skynet.init(function()
    require "common.init"
    require "app.game.init"
end)

skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, subCmd, ...)
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

	print("game service start")
    local nodeId = "game"
    local serviceId = ".main"
    skynet.name(serviceId, skynet.self())
    if skynet.getenv("id") == nodeId then
        skynet.newservice("debug_console",8000)
    end
    -- skynet.newservice("login")
    if skynet.getenv("cluster_port") then
        skynet.uniqueservice("nodeMgr")
    end
    clusterMgr = ClusterMgr.new()
    clusterMgr:register(serviceId)
    clusterMgr:send("gate", ".protoLoader", "register", table.keys(Client), skynet.getenv("id"))
    playerMgr = PlayerMgr.new()
end)