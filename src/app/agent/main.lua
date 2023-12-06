local skynet = require "skynet"

skynet.init(function()
    require "common.init"
    require "app.agent.init"
end)

skynet.start(function()
	print("agent service start")
    local nodeId = "agent"
    local serviceId = ".main"
    skynet.name(serviceId, skynet.self())
    local debug_port = skynet.getenv("debug_port")
    if debug_port then
        skynet.uniqueservice("debug_console", debug_port)
    end
    skynet.uniqueservice("agentMgr")
    if skynet.getenv("cluster_port") then
        NODE_MGR.register(serviceId)
        NODE_MGR.init()
    end
	print("agent service exit")
end)