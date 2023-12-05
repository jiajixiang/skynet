local skynet = require "skynet"
require "skynet.manager"

local function getUpdateFilePath()
    local updatePath = skynet.getenv("updatePath")

    return "../../src/"..updatePath
end

local function tryUpdateFile()
	local updateFilePath = getUpdateFilePath()
	local func, err = loadfile(updateFilePath)
	local tbl = func()
	if tbl.needUpdate then
		local file_list = tbl.fileList
		for _, fileName in ipairs(file_list) do
        end
    end
end

skynet.init(function()
    require "common.init"
end)

skynet.start(function()
    local serviceId = ".autoUpdate"
	skynet.register(serviceId)

    while true do
        skynet.sleep(100)
        tryUpdateFile()
    end
end)
