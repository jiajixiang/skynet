PlayerMgr = class("PlayerMgr")
allPlayers = {}
allAccountTbl = {}

function getPlayer(pid)
    return allPlayers[pid]
end

function getPlayersByAccount(account)
    local ret = {}
    for pid, player in pairs(allPlayers) do
        if player.account == account then
            ret[#ret + 1] = player.pid
        end
    end
    return ret
end

function addPlayer(account, name)
    local player = PLAYER.createPlayer(name, account)
    allPlayers[player.pid] = player
    if not allAccountTbl[player.account] then
        allAccountTbl[player.account] = {}
    end
    allAccountTbl[player.account][player.pid] = player
    return player
end

local function onReqCreatePlayer(fd, args)
    local account = args.account
    local name = args.name
    -- local player = playerMgr:addPlayer(account, name)
    local player = addPlayer(account, name)
    player:sendToClient(fd, "S2C_Create_Player", {
        pid = player.pid,
        result = 1,
    })
    return true
end

local function onQueryPlayers(account)
    if allAccountTbl[account] then
        return table.keys(allAccountTbl[account])
    end
end

function __init__()
    for_maker.C2S_Create_Player = onReqCreatePlayer

    for_internal.reqQueryPlayers = onQueryPlayers
end