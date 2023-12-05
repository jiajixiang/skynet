local skynet = require "skynet"

Rpc = {}
Client = {}
skynet.init(function()
    require "common.init"
    require "app.login.init"
end)

skynet.start(function()
    skynet.dispatch("lua", function (session, address, cmd, subCmd, ...)
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

	print("login service start")
    local nodeId = "login"
    local serviceId = ".main"
    skynet.name(serviceId, skynet.self())
    local debug_port = skynet.getenv("debug_port")
    if debug_port then
        skynet.uniqueservice("debug_console", debug_port)
    end
    if skynet.getenv("cluster_port") then
        skynet.uniqueservice("nodeMgr")
    end
    clusterMgr = ClusterMgr.new()
    clusterMgr:register(serviceId)
    loginMgr = LoginMgr.new()
    skynet.uniqueservice("protoLoader")
    skynet.newservice("gateMgr")
    clusterMgr:send("login", ".protoLoader", "register", table.keys(Client), skynet.getenv("id"))
	print("login service exit")
    LoginMgr = Import("app/login/loginMgr.lua")
end)
