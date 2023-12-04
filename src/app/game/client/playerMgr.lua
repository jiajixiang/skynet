local client = Client

function client.C2S_Create_Player(fd, args)
    print(fd, table.dump(args))
    local account = args.account
    local name = args.name
    local player = PlayerMgr:addPlayer(account, name)
    player:sendToClient(fd, "S2C_Create_Player", {
        pid = player.pid,
        result = 1,
    })
    return true
end