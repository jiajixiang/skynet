local skynet = require "skynet"
function sendToClient(fd, cmd, args)
    for_internal.s2cMessageToClient(fd, cmd, args)
end

local function onReqLogin(fd, args)
    local account = args.account
    local password = args.password
    LOGIN_MGR.sendToClient(fd, "S2C_Login", {
        account = args.account,
        result = 1,
    })
    return true
end

local function onReqLogout(fd, args)
    LOGIN_MGR.sendToClient(fd, "S2C_Logout", {
        id = fd,
        result = 1,
    })
end

function __init__()
    for_maker.C2S_Login = onReqLogin
    for_maker.C2S_Logout = onReqLogout
end