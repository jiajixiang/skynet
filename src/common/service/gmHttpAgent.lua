local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local string = string
local log = require "log"

local function response(id, ...)
    local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
    if not ok then
        -- if err == sockethelper.socket_error , that meanssocket closed.
        skynet.error(string.format("fd = %d, %s", id, err))
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, id)
        socket.start(id) --开始接收一个socket
        -- limit request body size to 8192 (you can pass nil to unlimit)
        --一般的业务不需要处理大量上行数据,为了防止攻击,做了一个8K限制。这个限制可以去掉。
        local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
        if code then
            if code ~= 200 then --如果协议解析有问题,就回应一个钱错误码code。
                response(id, code)
            else
                --这是一个示范的回应过程,你可以根据你的实际需要,解析url,method 和 header 做出回应。
                if header.host then
                    log.debug("header host", header.host)
                end
                local path, query = urllib.parse(url)
                log.debug(string.format("path: %s", path))
                local color, text = "red", "hello"
                if query then
                    local q = urllib.parse_query(query) --获取请求的参数
                    for k, v in pairs(q) do
                        log.debug(string.format("query: %s= %s", k, v))
                        if (k == "color") then
                            color = v
                        elseif (k == "text") then
                            text = v
                        end
                    end
                end
                response(id, code)
            end
        else
            --如果抛出的异常是sockethelper.socket_error表示是客户端网络断开了。
            if url == sockethelper.socket_error then
                log.debug("socket closed")
            else
                log.debug(url)
            end
        end
        socket.close(id)
    end)
end)
