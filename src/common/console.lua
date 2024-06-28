local skynet = require "skynet"
local snax   = require "skynet.snax"
local socket = require "skynet.socket"

-- function socket.lock(id)
-- 	local s = socket_pool[id]
-- 	assert(s)
-- 	local lock_set = s.lock
-- 	if not lock_set then
-- 		lock_set = {}
-- 		s.lock = lock_set
-- 	end
-- 	if #lock_set == 0 then
-- 		lock_set[1] = true
-- 	else
-- 		local co = coroutine.running()
-- 		table.insert(lock_set, co)
-- 		skynet.wait(co)
-- 	end
-- end

-- function socket.unlock(id)
-- 	local s = socket_pool[id]
-- 	assert(s)
-- 	local lock_set = assert(s.lock)
-- 	table.remove(lock_set,1)
-- 	local co = lock_set[1]
-- 	if co then
-- 		skynet.wakeup(co)
-- 	end
-- end

local function split_cmdline(cmdline)
	local split = {}
	for i in string.gmatch(cmdline, "%S+") do
		table.insert(split,i)
	end
	return split
end

local function console_main_loop()
	local stdin = socket.stdin()
    if not stdin then
        return
    end
    -- socket.lock(stdin)
	while true do
		local cmdline = socket.readline(stdin, "\n")
        if not cmdline then
            break
        end
		local split = split_cmdline(cmdline)
		local command = split[1]
		if command == "snax" then
			pcall(snax.newservice, select(2, table.unpack(split)))
		elseif cmdline ~= "" then
			pcall(skynet.send, ".main", "lua", "internal", cmdline)
			--pcall(skynet.newservice, cmdline)
		end
	end
    -- socket.unlock(stdin)
end

skynet.start(function()
	skynet.fork(console_main_loop)
end)
