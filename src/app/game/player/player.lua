local Player = class("Player")

function Player:ctor(pid, name, account)
    self.pid = pid
    self.name = name
    self.account = account
end

function Player:sendToClient(fd, cmd, args)
    clusterMgr:send("gate", ".gateMgr", "sendToClient", fd, cmd, args)
end

return Player