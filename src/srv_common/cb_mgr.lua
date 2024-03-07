cbGlobalId = 0

callBackTbl = {}

function fetchCallbackId(func, ...)
    cbGlobalId = cbGlobalId + 1

    callBackTbl[cbGlobalId] = {
        f = func,
        paramTbl = {...}
    }

    return cbGlobalId
end

function fetchFreCallbackId(func, ...)
    cbGlobalId = cbGlobalId + 1

    callBackTbl[cbGlobalId] = {
        f = func,
        paramTbl = {...},
        isCallFre = true
    }

    return cbGlobalId
end

function getCBInfo(id)
    return callBackTbl[id]
end

function clearCBInfo(id)
    callBackTbl[id] = nil
end

