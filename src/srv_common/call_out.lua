needRefCalloutTbl = {}
noStopCBTbl = {}

local function doCB(id)
end

function callOnce(func, time, ...)
	assert(func)
	if time <= 0 then
		time = 0.1
	end
	local id = CB_MGR.fetchCallbackId(func, ...)
	lcallout.callOnce(id, time)

	needRefCalloutTbl[id] = TIME.osBJSec() + time

	return id
end