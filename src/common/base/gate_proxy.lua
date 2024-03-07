local saveFieldTbl = {
}

local nodeName = "gate"
local serviceName = ".main"
clsGateProxy = PROXY.clsProxy:Inherit()

function clsGateProxy:__init__(oci)
    Super(clsGateProxy).__init__(self, oci)

    for k, func in pairs(saveFieldTbl) do
        if oci[k] == nil then
            self[k] = func()
        else
            self[k] = oci[k]
        end
    end
end

local function createGateProxy()
    local oci = {
        _nodeName = nodeName,
        _serviceName = serviceName
    }
	local gateProxyObj = clsGateProxy:New(oci)
    return gateProxyObj
end

local function _allocProxy()
    local proxyObj = PROXY.getProxy(nodeName, serviceName)
    if not proxyObj then
        proxyObj = createGateProxy()
    end
    return proxyObj
end

function protoRedirectRegiste(...)
    local proxyObj = _allocProxy()
    proxyObj:send("internal", "protoRedirectRegiste", ...)
end

function s2cMessageToClient(...)
    local proxyObj = _allocProxy()
    proxyObj:send("internal", "s2cMessageToClient", ...)
end
