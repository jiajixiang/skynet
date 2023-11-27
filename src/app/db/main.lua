local skynet = require "skynet"

function getLocalIp()
    local str = (io.popen "ip addr"):read "*a"
	local ret = {}
    local fun = function(a)
        local str = string.sub(a,1,string.find(a,'/')-1)
        print(str)
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
    local nodeName = "db"
    local serviceName = ".db"
    skynet.name(serviceName, skynet.self())
    if skynet.getenv("id") == nodeName then
        skynet.newservice("debug_console",8000)
    end
    if skynet.getenv("cluster_prot") then
        skynet.newservice("nodeMgr")
    end
    local clusterProxy = ClusterProxy.new()
    clusterProxy:register(serviceName)
	print("db service exit")
    skynet.exit()
end)