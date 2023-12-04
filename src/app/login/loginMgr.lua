local LoginMgr = class("LoginMgr")
function LoginMgr:ctor()

end

function LoginMgr:sendToClient(fd, cmd, args)
    clusterMgr:send("login", ".gateMgr", "sendToClient", fd, cmd, args)
end

return LoginMgr