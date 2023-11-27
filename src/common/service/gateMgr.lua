local skynet = require "skynet"
local netpack = require "skynet.netpack"
local socketdriver = require "skynet.socketdriver"
local connection ={}
local handler
local MSG = {}
local listen_context = {}

local socket	-- listen socket
local queue		-- message queue
local CMD = setmetatable({}, { __gc = function() netpack.clear(queue) end })
local nodelay = false

local function dispatch_msg(fd, msg, sz)
    if connection[fd] then
        handler.message(fd, msg, sz)
    else
        skynet.error(string.format("Drop message from fd (%d) : %s", fd, netpack.tostring(msg, sz)))
    end
end

MSG.data = dispatch_msg

local function dispatch_queue()
    local fd, msg, sz = netpack.pop(queue)
    if fd then
        -- may dispatch even the handler.message blocked
        -- If the handler.message never block, the queue should be empty, so only fork once and then exit.
        skynet.fork(dispatch_queue)
        dispatch_msg(fd, msg, sz)

        for fd, msg, sz in netpack.pop, queue do
            dispatch_msg(fd, msg, sz)
        end
    end
end

MSG.more = dispatch_queue

function MSG.open(fd, msg)
    if nodelay then
        socketdriver.nodelay(fd)
    end
    connection[fd] = true
    handler.connect(fd, msg)
end

function MSG.close(fd)
    if fd ~= socket then
        if connection[fd] then
            connection[fd] = false -- close read
        end
        if handler.disconnect then
            handler.disconnect(fd)
        end
    else
        socket = nil
    end
end

function MSG.error(fd, msg)
    if fd == socket then
        skynet.error("gateserver accept error:", msg)
    else
        socketdriver.shutdown(fd)
        if handler.error then
            handler.error(fd, msg)
        end
    end
end

function MSG.warning(fd, size)
    if handler.warning then
        handler.warning(fd, size)
    end
end

function MSG.init(id, addr, port)
    if listen_context then
        local co = listen_context.co
        if co then
            assert(id == listen_context.fd)
            listen_context.addr = addr
            listen_context.port = port
            skynet.wakeup(co)
            listen_context.co = nil
        end
    end
end


function CMD.open(source, conf)
    assert(not socket)
    local address = "0.0.0.0"
    local port = tonumber(skynet.getenv("port"))
    nodelay = true
    skynet.error(string.format("Listen on %s:%d", address, port))
    socket = socketdriver.listen(address, port)
    listen_context.co = coroutine.running()
    listen_context.fd = socket
    skynet.wait(listen_context.co)
    conf.address = listen_context.addr
    conf.port = listen_context.port
    listen_context = nil
    socketdriver.start(socket)
    if handler and handler.open then
        return handler.open(source, conf)
    end
end

function CMD.close()
    assert(socket)
    socketdriver.close(socket)
end

skynet.register_protocol {
    name = "socket",
    id = skynet.PTYPE_SOCKET, -- PTYPE_SOCKET = 6
    unpack = function(msg, sz)
        return netpack.filter(queue, msg, sz)
    end,
    dispatch = function(_, _, q, type, ...)
        queue = q
        if type then
            MSG[type](...)
        end
    end
}

skynet.start(function (handler)
    skynet.dispatch("lua", function (session, address, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.ret(skynet.pack(f(address, ...)))
        else
            skynet.ret(skynet.pack(handler.command(cmd, address, ...)))
        end
    end)
end)