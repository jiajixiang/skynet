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

skynet.init(function()
    require "common.init"
    require "app.db.init"
end)

skynet.start(function()
	print("db service start")
    local nodeId = "db"
    local serviceId = ".db"
    skynet.name(serviceId, skynet.self())
    local debug_port = skynet.getenv("debug_port")
    if debug_port then
        skynet.uniqueservice("debug_console", debug_port)
    end
    if skynet.getenv("cluster_port") then
        NODE_MGR.register(serviceId)
        NODE_MGR.init()
    end

	print("db service exit")
    skynet.exit()
end)