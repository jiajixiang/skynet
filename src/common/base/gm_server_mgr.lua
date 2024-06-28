local skynet = require "skynet"
local socket = require "skynet.socket"

AllAgent = {}

function afterInitModule()

end

function onNodeStart()
    for i= 1, 20 do
        --启动20个代理服务用于处理http请求
        AllAgent[i] = skynet.newservice("gmHttpAgent")
    end
    local balance = 1
    --监听一个web端口
    local id = socket.listen("0.0.0.0", 8001)
    socket.start(id,function(id,addr)
        --当一个http请求到达的时候,把socketid分发到事先准备好的代理中去处理。
        skynet.error(string.format("%s connected, pass it to aagent:%08x",addr, AllAgent[balance]))
        skynet.send(AllAgent[balance], "lua", id)
        balance = balance + 1
        if balance > #AllAgent then
        balance = 1
        end
    end)
end

function __init__( ... )

end