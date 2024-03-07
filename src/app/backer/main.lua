local skynet = require "skynet"

function getLocalIp()
    local str = (io.popen "ip addr"):read "*a"
	local ret = {}
    local fun = function(a)
        local str = string.sub(a,1,string.find(a,'/')-1)
        if str~= '127.0.0.1' then 
            ip = str
        end
    end
    str=string.gsub(str,'%d*%.%d*%.%d*%.%d*/',fun)
    return ip
end

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
	"app.backer.global",
}

skynet.init(function()
    for _, file in ipairs(DOFILELIST) do
        require(file)
    end
end)

skynet.start(function()
	print("backer service start")
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
    local nodeId = "backer"
    local serviceId = ".main"
    skynet.name(serviceId, skynet.self())
    local debug_port = skynet.getenv("debug_port")
    if debug_port then
        skynet.uniqueservice("debug_console", debug_port)
    end
    if skynet.getenv("cluster_port") then
        NODE_MGR.register(serviceId)
    end

	print("db service exit")
end)