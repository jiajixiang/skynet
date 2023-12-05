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
    local debug_port = skynet.getenv("debug_port")
    if debug_port then
        skynet.uniqueservice("debug_console", debug_port)
    end
    -- skynet.newservice("login")
    if skynet.getenv("cluster_port") then
        skynet.uniqueservice("nodeMgr")
    end
    clusterMgr = ClusterMgr.new()
    clusterMgr:register(serviceId)
    clusterMgr:send("gate", ".protoLoader", "register", table.keys(Client), skynet.getenv("id"))
    playerMgr = PlayerMgr.new()
    PLAYER_MGR = Import("app/game/player/playerMgr.lua")
    for key, value in pairs(PLAYER_MGR) do
        print(key, value)
    end
    skynet.uniqueservice("autoUpdata")
	print("game service exit")
end)