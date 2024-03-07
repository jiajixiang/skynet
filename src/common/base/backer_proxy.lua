local saveFieldTbl = {
}

local nodeName = "backer"
local serviceName = ".main"

clsBackerProxy = PROXY.clsProxy:Inherit()

function clsBackerProxy:__init__(oci)
    Super(clsBackerProxy).__init__(self, oci)

    for k, func in pairs(saveFieldTbl) do
        if oci[k] == nil then
            self[k] = func()
        else
            self[k] = oci[k]
        end
    end
end

local function createBackerProxy()
    local oci = {
        _nodeName = nodeName,
        _serviceName = serviceName
    }
	local backerProxyObj = clsBackerProxy:New(oci)
    return backerProxyObj
end

local function _allocProxy()
    local proxyObj = PROXY.getProxy(nodeName, serviceName)
    if not proxyObj then
        proxyObj = createBackerProxy()
    end
    return proxyObj
end

function find(...)
    local proxyObj = _allocProxy()
    return proxyObj:call("internal", "db_find_value", ...)
end

function findOne(...)
    local proxyObj = _allocProxy()
    return proxyObj:call("internal", "db_find_one_value", ...)
end

function update(...)
    local proxyObj = _allocProxy()
    return proxyObj:call("internal", "db_update_value", ...)
end
