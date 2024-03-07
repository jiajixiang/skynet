local globalUserId = 0
local function getNewUserId()
    globalUserId = globalUserId + 1
    return globalUserId
end

allAccountTbl = {
    --[[
	[account] = userObj
	--]]
}

allUserTbl = {
    --[[
	[userId] = userObj
	--]]
}

allUserVfdTbl = {
    --[[
	[vfd] = userObj
	--]]
}

local saveFieldTbl = {
    _userId = function()
        return nil
    end,
    _account = function()
        return nil
    end,
    _name = function()
        return nil
    end,
}

function getUserByVfd(vfd)
    return allUserVfdTbl[vfd]
end

function getUserByAccount(account)
    return allAccountTbl[account]
end

clsUser = clsObject:Inherit()

function clsUser:__init__(oci)
    Super(clsUser).__init__(self, oci)
    for k, func in pairs(saveFieldTbl) do
        if oci[k] == nil then
            self[k] = func()
        else
            self[k] = oci[k]
        end
    end
    self._vfd = oci._vfd
    allAccountTbl[self._account] = self
    allUserTbl[self._userId] = self
    allUserVfdTbl[self._vfd] = self
end

function clsUser:setName(name)
    self._name = name
end

function clsUser:sendToClient(vfd, cmd, args)
    GATE_PROXY.s2cMessageToClient(vfd, cmd, args)
end

function createUser(vfd, account)
    local oci = {
        _vfd = vfd,
        _account = account,
        _userId = getNewUserId()
    }
    local userObj = clsUser:New(oci)
    return userObj
end

local function onReqCreatePlayer(vfd, name)
    local userObj = getUserByVfd(vfd)
    if not userObj then
        userObj = createUser(vfd, name)
    end
    userObj:setName(name)
    userObj:sendToClient(vfd, "S2C_Create_Player", {
        pid = userObj.userId,
        result = 1,
    })
end

local function onQueryRoles(vfd, account)
    local userObj = getUserByAccount(account)
    if not userObj then
        userObj = createUser(vfd, account)
    end
    return userObj
end

function __init__()
    for_maker.C2S_Create_Player = onReqCreatePlayer
    for_internal.reqQueryRoles = onQueryRoles
end