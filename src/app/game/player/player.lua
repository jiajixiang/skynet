local Player = class("Player")

local globalPid = 0
local function getNewPid()
    globalPid = globalPid + 1
    return globalPid
end

function Player:ctor(pid, name, account)
    self.pid = pid
    self.name = name
    self.account = account
end

function Player:sendToClient(fd, cmd, args)
    clusterMgr:send("gate", ".gateMgr", "sendToClient", fd, cmd, args)
end

function createPlayer(account, name)
    local pid = getNewPid()
    return Player.new(pid, account, name)
end