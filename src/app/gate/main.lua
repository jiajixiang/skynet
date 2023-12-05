local skynet = require "skynet"
local pb = require "protobuf"

for_internal = {}
for_maker = {}

skynet.init(function()
    require "common.init"
    require "app.gate.global"
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

	print("gate service start")
    local serviceId = ".main"
    skynet.name(serviceId, skynet.self())
    if skynet.getenv("cluster_port") then
        skynet.uniqueservice("nodeMgr")
    end
    local debug_port = skynet.getenv("debug_port")
    if debug_port then
        skynet.uniqueservice("debug_console", debug_port)
    end
    clusterMgr = ClusterMgr.new()
    clusterMgr:register(serviceId)
    skynet.uniqueservice("protoLoader")
    skynet.uniqueservice("gateMgr")
    -- while true do
    --     local cmd = io.read()
    --     if cmd == "stop" then
    --         local service_mgr = skynet.localname(".service")
    --         local ret = skynet.call(service_mgr, "lua", "LIST")
    --         for _, addr in pairs(ret) do
    --             skynet.send(addr, "lua", "stop")
    --         end
    --         skynet.abort()
    --         print("gate service exit")
    --     end
    -- end
end)