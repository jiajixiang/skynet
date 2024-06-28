local skynet = require "skynet"
local log = require "log"
require "skynet.manager"

local function getUpdateFilePath()
    local updatePath = skynet.getenv("updatePath")

    return "../../src/"..updatePath
end

local function notifyHotfix(fileList)
end

local function tryUpdateFile()
	local updateFilePath = getUpdateFilePath()
	local func, err = loadfile(updateFilePath)
	local tbl = func()
	if not tbl.needUpdate then
        return
    end
    local hotfixList = {}
    local fileList = tbl.fileList
    for _, fileName in ipairs(fileList) do
        log.debug(fileName)
    end
end

local function startTimer( ... )
    skynet.timeout(100, onTimer)
end

function onTimer()
    tryUpdateFile()
    startTimer()
end

skynet.init(function()

end)

skynet.start(function()
    local serviceId = ".autoUpdate"
	skynet.register(serviceId)

    startTimer()
end)
