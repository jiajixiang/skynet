local client = Client

function client.C2S_Login(fd, args)
    print(fd, table.dump(args))
    local account = args.account
    local password = args.password

    loginMgr:sendToClient(fd, "S2C_Login", {
        account = args.account,
        result = 1,
    })
    return true
end

function client.C2S_Logout(fd, args)
    print(fd, table.dump(args))
    local account = args.account
    local password = args.password

    loginMgr:sendToClient(fd, "S2C_Login", {
        account = args.account,
        result = 1,
    })
end
