local saveFieldTbl = {
}

local nodeName = "backer"
local serviceName = ".main"

clsDbProxy = PROXY.clsProxy:Inherit()

function clsDbProxy:__init__(oci)
    Super(clsDbProxy).__init__(self, oci)

    for k, func in pairs(saveFieldTbl) do
        if oci[k] == nil then
            self[k] = func()
        else
            self[k] = oci[k]
        end
    end
end

local function createDbProxy()
    local oci = {
        _nodeName = nodeName,
        _serviceName = serviceName
    }
	local dbProxyObj = clsDbProxy:New(oci)
    return dbProxyObj
end

local function _allocProxy()
    local proxyObj = PROXY.getProxy(nodeName, serviceName)
    if not proxyObj then
        proxyObj = createDbProxy()
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
