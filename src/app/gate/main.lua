local skynet = require "skynet"
local pb = require "protobuf"

skynet.init(function()
    require "common.init"
    require "app.gate.init"
end)

--protobuf编码解码
function test4()
    pb.register_file("../protobuf/all.pb")
    --编码
    local msg = {
        id = 101,
        pw = "123456",
    }
    local buff = pb.encode("C2S_Login", msg)
    print("len:"..string.len(buff))
    --解码
    local umsg = pb.decode("C2S_Login", buff)
    if umsg then
        print("id:"..umsg.id)
        print("pw:"..umsg.pw)
    else
        print("error")
    end
end

skynet.start(function()
    skynet.dispatch("lua", function (session, address, cmd, ...)
        print(session, address, cmd, ...)
	end)

	print("gate service start")
    local nodeName = "gate"
    local serviceName = ".gate"
    skynet.name(serviceName, skynet.self())
    if skynet.getenv("id") == nodeName then
        skynet.newservice("debug_console",8000)
    end
    if skynet.getenv("cluster_prot") then
        skynet.uniqueservice(true, "nodeMgr")
    end
    clusterProxy = ClusterProxy.new()
    clusterProxy:register(serviceName)
    local ret = clusterProxy:reload()
    print(table.dump(ret))
    if skynet.getenv("id") == nodeName then
        clusterProxy:open()
    end
    -- local ret = skynet.call(cluster, "lua", "send", "gate", ".gate", "set", "-------")
    -- print(ret)
    test4()
	print("gate service exit")
end)