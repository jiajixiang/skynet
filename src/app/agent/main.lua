local skynet = require "skynet"

skynet.init(function()
    require "common.init"
    require "app.agent.init"
end)

skynet.start(function()
	print("agent service start")
    local nodeName = "agent"
    local serviceName = ".agent"
    skynet.name(serviceName, skynet.self())
    if skynet.getenv("id") == nodeName then
        skynet.newservice("debug_console",8000)
    end
    cluster = ClusterRpc.new(serviceName)
    cluster:start()
	print("agent service exit")
    skynet.exit()
end)