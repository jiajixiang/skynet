local function onFindValue(col, ...)
    local db = MONGO.getDb(col)
    local cursor = db[col]:find(...)
    local datas = {}
    while cursor:hasNext() do
        local data = cursor:next()
        datas[#datas+1] = data
    end
    return datas
end

local function onFindOneValue(col, ...)
    local db = MONGO.getDb(col)
    return db[col]:findOne(...)
end

local function onUpdateValue(col, ...)
    local db = MONGO.getDb(col)
    return db[col]:update(...)
end

function __init__()
    for_internal.db_find_value = onFindValue
    for_internal.db_find_one_value = onFindOneValue
    for_internal.db_update_value = onUpdateValue
end