-- exec address "lua code"
function COMMANDX.exec(cmd)
	local address = adjust_address(cmd[2])
	local luacode = assert(cmd[1]:match("%S+%s+%S+%s(.+)%c$") , "need lua code string")
	return skynet.call(address, "debug", "EXEC", luacode)
end

-- print address "lua code" deepth
function COMMANDX.print(cmd)
	local address = adjust_address(cmd[2])
	local cmdstr, deepth = cmd[1]:match("(.+)%s+(%d+)%c$")
	if not cmdstr then
		cmdstr = cmd[1]:match("(.+)%c$")
	end
	local luacode = cmdstr:match("%S+%s+%S+%s(.+)")
	--local luacode, deepth = cmd[1]:match("%S+%s+%S+%s(%S*)%s*(%d*)%c$")
	skynet.error(string.format("echo luacode: %s, deepth: %s", luacode, deepth or "nil"))
	return skynet.call(address, "debug", "PRINT", luacode, deepth)
end

//tools/skynet/service/debug_console.lua