local skynet = require "skynet"
require "skynet.manager" -- 除了需要引入skynet包以外还要再引入skynet.manager包。
for_internal = {}
for_maker = {}
for_cluster = {}

local DOFILELIST =
{
	"common.common_class",
	"srv_common.base.class",
	"srv_common.base.import",
	"srv_common.base.table",
	--"srv_common.base.extend",
	--"srv_common.base.ldb",
	"app.game.global",
}

skynet.init(function()
    for _, file in ipairs(DOFILELIST) do
        require(file)
    end
end)

skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, subCmd, ...)
        if cmd == "client" then
            local func = for_maker[subCmd]
            skynet.ret(skynet.pack(func(...)))
        elseif cmd == "cluster" then
            local func = for_cluster[subCmd]
            skynet.ret(skynet.pack(func(...)))
        elseif cmd == "internal" then
            local func = for_internal[subCmd]
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
    if skynet.getenv("cluster_port") then
        NODE_MGR.systemStartup()
        NODE_MGR.startNode()
    end
    GATE_PROXY.protoRedirectRegiste(table.keys(for_maker), skynet.getenv("id"))
    skynet.uniqueservice("autoUpdata")
    print("game service exit")
end)
