PlayerMgr = class("PlayerMgr")

allPlayers = {}
globalPid = 0

function getPlayer(pid)
    return allPlayers[pid]
end

local function getNewPid()
    globalPid = globalPid + 1
    return globalPid
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
    local pid = getNewPid()
    local player = Player.new(pid, name, account)
    allPlayers[pid] = player
    return player
end