local skynet = require "skynet"

skynet.init(function()
    require "common.init"
    require "app.agent.init"
end)

skynet.start(function()
	print("agent service start")
    local nodeId = "agent"
    local serviceId = ".agent"
    skynet.name(serviceId, skynet.self())
    if skynet.getenv("id") == nodeId then
        skynet.newservice("debug_console",8000)
    end
    cluster = ClusterRpc.new(serviceId)
    cluster:start()
	print("agent service exit")
    skynet.exit()
end)