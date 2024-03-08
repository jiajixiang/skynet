function dbgcmd.EXEC(luacode)
    skynet.error(string.format("Lua code exec string: %s", luacode))
    local errmsg
    xpcall(
        function() load(luacode)() end,
        function(e) errmsg = tostring(e) .."\n" .. debug.traceback() end
    )
    if errmsg then
        skynet.error(string.format("Lua code exec fail. errmsg: %s", errmsg))
    end
    skynet.ret(skynet.pack(errmsg or "exec ok"))
end

function dbgcmd.PRINT(luacode, deepth)
    skynet.error(string.format("Lua code echo string: %s, deepth: %s", luacode, tostring(deepth)))
    local errmsg
    local ok, result = xpcall(
        function() return {load("return " .. luacode)()} end,
        function(e) errmsg = tostring(e) .."\n" .. debug.traceback() end
    )
    if errmsg then
        skynet.error(string.format("Lua code echo fail. errmsg: %s", errmsg))
        skynet.ret(skynet.pack(errmsg))
    else
        skynet.error("Lua code echo ok.")
        if table.dump then
            if skynet.getenv("tableDumpFormat") then
                skynet.ret(skynet.pack(table.dump(result, tonumber(deepth), {excludeKeys={player=true,owner=true}})))
            else
                skynet.ret(skynet.pack(table.dump(result, tonumber(deepth))))
            end
        else
            skynet.ret(skynet.pack(tostring(result)))
        end
    end
end

// 添加至 tools/skynet/lualib/skynet/debug.lua