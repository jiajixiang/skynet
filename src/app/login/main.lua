local skynet = require "skynet"

for_internal = {}
for_maker = {}
for_cmd = {}
for_socket = {}


local DOFILELIST =
{
	"common.common_class",
	"srv_common.base.class",
	"srv_common.base.import",
	"srv_common.base.table",
	--"srv_common.base.extend",
	--"srv_common.base.ldb",
	"app.login.global",
}

skynet.init(function()
    for _, file in ipairs(DOFILELIST) do
        require(file)
    end
end)

skynet.start(function()
    skynet.dispatch("lua", function (session, address, cmd, subCmd, ...)
        if cmd == "client" then
            local func = for_maker[subCmd]
			skynet.ret(skynet.pack(func(...)))
        elseif cmd == "internal" then
            local func = for_internal[subCmd]
			skynet.ret(skynet.pack(func(...)))
        elseif cmd == "socket" then
            local func = for_socket[subCmd]
			skynet.ret(skynet.pack(func(...)))
            -- socket api don't need return
		else
            local func = for_cmd[cmd]
			if func then
				skynet.ret(skynet.pack(func(...)))
			else
				error(string.format("Unknown command %s", tostring(cmd)))
			end
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
        NODE_MGR.systemStartup()
    end
    skynet.uniqueservice("protoLoader")
	print("login service exit")
    -- local result = skynet.call(skynet.localname(".service"), "lua", "LIST")
    -- print(table.dump(result))
    -- for serverName, handle in pairs(result) do
    --     print(serverName)
    --     skynet.call(handle, "lua", "EXIT")
    -- end
end)
