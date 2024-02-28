local skynet = require "skynet"
local gateserver = require "snax.gateserver"
local netpack = require "skynet.netpack"
local crypt = require "skynet.crypt"
local socketdriver = require "skynet.socketdriver"
local assert = assert

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

local handler = {}
local user_online = {}

skynet.init(function ()
    require "common.init"
    NODE_MGR = Import("common/base/nodeMgr.lua")
end)

skynet.start(function ()
    local serviceId = ".agentMgr"
	skynet.register(serviceId)
    NODE_MGR.register(serviceId)
end)