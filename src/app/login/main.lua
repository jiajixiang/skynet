local skynet = require "skynet"

for_internal = {}
for_maker = {}

skynet.init(function()
    require "common.init"
    require "app.login.global"
end)

skynet.start(function()
    skynet.dispatch("lua", function (session, address, cmd, subCmd, ...)
        if cmd == "client" then
            local func = for_maker[subCmd]
			skynet.ret(skynet.pack(func(...)))
        elseif cmd == "cluster" then
            local func = for_internal[subCmd]
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
        NODE_MGR.register(serviceId)
        NODE_MGR.init()
    end
    skynet.uniqueservice("protoLoader")
    skynet.newservice("gateMgr")

    PROTO_PROXY.register(table.keys(for_maker), skynet.getenv("id"))
	print("login service exit")
end)
