local rpc = Rpc

function rpc.queryPlayers(account)
    return playerMgr.getPlayersByAccount(account)
end