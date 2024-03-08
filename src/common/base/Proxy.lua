local queue = require "skynet.queue"
local skynet = require "skynet"
local cluster = require "cluster"

AllProxyTbl = {}

local saveFieldTbl = {
    _nodeName = function()
        return nil
    end,
    _serviceName = function()
        return nil
    end
}

clsProxy = clsObject:Inherit()

function clsProxy:__init__(oci)
    Super(clsProxy).__init__(self, oci)

    for k, func in pairs(saveFieldTbl) do
        if oci[k] == nil then
            self[k] = func()
        else
            self[k] = oci[k]
        end
    end
    if skynet.getenv("id") ~= self._nodeName then
        self.proxy = cluster.proxy(self._nodeName, "@" .. self._serviceName)
    end

    if not AllProxyTbl[self._nodeName] then
        AllProxyTbl[self._nodeName] = {}
    end
    AllProxyTbl[self._nodeName][self._serviceName] = self
end

function clsProxy:send(...)
    if not self.proxy then
        local addr = skynet.localname(self._serviceName)
        return skynet.call(addr, "lua", ...)
    end
    return skynet.send(self.proxy, "lua", ...)
end

function clsProxy:call(...)
    if not self.proxy then
        local addr = skynet.localname(self._serviceName)
        return skynet.call(addr, "lua", ...)
    end
    return skynet.call(self.proxy, "lua", ...)
end

function getProxy(nodeName, serviceName)
    return AllProxyTbl[nodeName] and AllProxyTbl[nodeName][serviceName]
end

function tryGetProxy(nodeName, serviceName)
    local proxyObj = getProxy(nodeName, serviceName)
    if not proxyObj then
        local oci = {
            _nodeName = nodeName,
            _serviceName = serviceName
        }
        proxyObj = clsProxy:New(oci)
    end
    return proxyObj
end
