local skynet = require "skynet"
require "log"
require "skynet.manager" -- 除了需要引入skynet包以外还要再引入skynet.manager包。
for_internal = {}
for_maker = {}
for_cluster = {}

local DOFILELIST =
{
    -- "lutil",
	"common.common_class",
	"srv_common.base.class",
	"srv_common.base.import",
	"srv_common.base.table",
	--"srv_common.base.extend",
	--"srv_common.base.ldb",
	"app.game.global",
}

skynet.init(function()
    for _, file in ipairs(DOFILELIST) do
        require(file)
    end
end)

-- sighup cmd functions
local SIGHUP_CMD = {}

-- cmd for stop server
function SIGHUP_CMD.stop()
    -- TODO: broadcast stop signal
    log.warn("Handle SIGHUP, wlua will be stop.")
    skynet.sleep(100)
    skynet.abort()
end

-- cmd for cut log
function SIGHUP_CMD.cutlog()
    reopen_log()
end

-- cmd for reload
function SIGHUP_CMD.reload()
    log.warn("Begin reload.")
    skynet.call(".main", "lua", "reload")
    log.warn("End reload.")
end

local function get_sighup_cmd()
    local cmd = util_file.get_first_line(sighup_file)
    if not cmd then
        return
    end
    cmd = util_string.trim(cmd)
    return SIGHUP_CMD[cmd]
end

-- -- 捕捉sighup信号(kill -1)
-- skynet.register_protocol {
--     name = "SYSTEM",
--     id = skynet.PTYPE_SYSTEM,
--     unpack = function(...) return ... end,
--     dispatch = function(...)
--         print(...)
--         local func = get_sighup_cmd()
--         if func then
--             func()
--         else
--             log.error(string.format("Unknow sighup cmd, Need set sighup file. wlua_sighup_file: '%s'", sighup_file))
--         end
--     end
-- }

skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, subCmd, ...)
        if cmd == "client" then
            local func = for_maker[subCmd]
            skynet.ret(skynet.pack(func(...)))
        elseif cmd == "cluster" then
            local func = for_cluster[subCmd]
            skynet.ret(skynet.pack(func(...)))
        elseif cmd == "internal" then
            local func = for_internal[subCmd]
            skynet.ret(skynet.pack(func(...)))
        else
            error(string.format("Unknown command %s", tostring(cmd)))
        end
    end)

    print("game service start")
    local nodeId = "game"
    local serviceId = ".main"
    skynet.name(serviceId, skynet.self())
    local debug_port = skynet.getenv("debug_port")
    if debug_port then
        skynet.uniqueservice("debug_console", debug_port)
    end
    -- if skynet.getenv("cluster_port") then
    --     NODE_MGR.systemStartup()
    -- end
    -- GATE_PROXY.protoRedirectRegiste(table.keys(for_maker), skynet.getenv("id"))
    local console = skynet.uniqueservice("console")
    -- 
    -- pcall(skynet.send, ".main", "lua", "internal", cmdline)
    skynet.uniqueservice("autoUpdata")
    GM_SERVER_MGR.onNodeStart()
    print("game service exit")
    -- updateLuaFile("app/game/module/user/user.lua")
end)

-- 运行中界面输入 使用console