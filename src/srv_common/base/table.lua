-- @ingroup gg
-- @brief table扩展
-- @author sundream
-- @date 2018/12/25
-- @package table
-- comptiable with lua51
unpack = unpack or table.unpack
table.unpack = unpack
if table.pack == nil then
    function table.pack(...)
        return {
            n = select("#", ...),
            ...
        }
    end
end

-- @brief 判定集合: 是否有一个元素符合条件
-- @param set table 集合
-- @param func func 判定函数
-- @return bool 是否成立
function table.any(set, func)
    for k, v in pairs(set) do
        if func(k, v) then
            return true, k, v
        end
    end
    return false
end

-- @brief 判定集合: 是否所有元素符合条件
-- @param set table 集合
-- @param func func 判定函数
-- @return bool 是否成立
function table.all(set, func)
    for k, v in pairs(set) do
        if not func(k, v) then
            return false, k, v
        end
    end
    return true
end

-- @brief 过滤字典
-- @param tbl table 字典
-- @param func func 过滤函数
-- @return table 过滤后的新字典
function table.filterDict(tbl, func)
    local newtbl = {}
    for k, v in pairs(tbl) do
        if func(k, v) then
            newtbl[k] = v
        end
    end
    return newtbl
end

-- @brief 过滤列表
-- @param list table 列表
-- @param func func 过滤函数
-- @return table 过滤后的新列表
function table.filter(list, func)
    local new_list = {}
    for i, v in ipairs(list) do
        if func(v) then
            new_list[#new_list + 1] = v
        end
    end
    return new_list
end

-- @brief 从序列中找最大元素
function table.max(func, ...)
    if type(func) ~= "function" then
        return math.max(...)
    end
    local args = table.pack(...)
    local max
    for i, arg in ipairs(args) do
        local val = func(arg)
        if not max or val > max then
            max = val
        end
    end
    return max
end

-- @brief 从序列中找最小元素
function table.min(func, ...)
    if type(func) ~= "function" then
        return math.min(...)
    end
    local args = table.pack(...)
    local min
    for i, arg in ipairs(args) do
        local val = func(arg)
        if not min or val < min then
            min = val
        end
    end
    return min
end

function table.map(func, ...)
    local args = table.pack(...)
    assert(#args >= 1)
    func = func or function(...)
        return {...}
    end
    local maxn = table.max(function(tbl)
        return #tbl
    end, ...)
    local len = #args
    local newtbl = {}
    for i = 1, maxn do
        local list = {}
        for j = 1, len do
            table.insert(list, args[j][i])
        end
        local ret = func(table.unpack(list))
        table.insert(newtbl, ret)
    end
    return newtbl
end

-- @brief 从表中查找符合条件的元素
-- @param tbl table 表
-- @param func func 匹配函数/值
-- @return k,v 找到的键值对
function table.find(tbl, func)
    local isfunc = type(func) == "function"
    for k, v in pairs(tbl) do
        if isfunc then
            if func(k, v) then
                return k, v
            end
        else
            if func == v then
                return k, v
            end
        end
    end
end

-- @brief 获取表的所有键
-- @param t table 表
-- @return table 所有键构成的列表
function table.keys(t)
    local ret = {}
    for k, v in pairs(t) do
        ret[#ret + 1] = k
    end
    return ret
end

-- @brief 获取表的所有值
-- @param t table 表
-- @return table 所有值构成的列表
function table.values(t)
    local ret = {}
    for k, v in pairs(t) do
        ret[#ret + 1] = v
    end
    return ret
end

-- @brief 树型dump一个 table,不用担心循环引用
-- depthMax 打印层数控制，默认3层（-1表示无视层数）
-- options 选项table
--   options.excludeKey 排除打印的key
--   options.excludeType 排除打印的值类型
--   options.noAlignLine 不打印对齐线
--   options.oneLine 打印成一行
function table._dump(root, depthMax, options)
    if type(root) ~= "table" then
        return root
    end

    -- options
    depthMax = depthMax or 8
    local excludeKeys = options and options.excludeKeys
    local excludeTypes = options and options.excludeTypes
    local noAlignLine = options and options.noAlignLine
    local oneLine = options and options.oneLine

    local concat = table.concat
    local eq, bktL, bktR, bktRC, comma, empty, ellipsis, sep = " = ", "{", "}", "},", ",", "", "...", "\n"
    local align1, align2 = "    ", "│   "
    if noAlignLine then
        align2 = align1
    end
    if oneLine then
        sep, align1, align2 = "", "", ""
    end

    local cache = {
        [root] = "."
    }
    local temp = {bktL}
    local valtb = {'\"', '', '\"'}
    local keytb1, keytb2 = {"[", "", "]"}, {"[\"", "", "\"]"}
    local function _dump(t, space, name, depth)
        local indent1, indent2 = space .. align1, space .. align2
        for k, v in pairs(t) do
            local kType, vType = type(k), type(v)
            local isLast = not next(t, k) -- 最后一个字段
            local endMark = isLast and empty or comma
            local tbktR = isLast and bktR or bktRC
            local keytb = kType == "string" and keytb2 or keytb1
            keytb[2] = tostring(k)
            local keyBkt = concat(keytb)

            if vType == "table" then
                if cache[v] then
                    temp[#temp + 1] = concat({space, keyBkt, eq, bktL, cache[v], tbktR})
                else
                    local new_key = name .. "." .. tostring(k)
                    cache[v] = new_key .. " ->[" .. tostring(v) .. "]"

                    -- table 深度判断
                    if (depthMax > 0 and depth >= depthMax) or (excludeKeys and excludeKeys[k]) then
                        temp[#temp + 1] = concat({space, keyBkt, eq, bktL, ellipsis, tbktR})
                    else
                        if next(v) then
                            -- 非空table
                            temp[#temp + 1] = concat({space, keyBkt, eq, bktL})
                            local indent = isLast and indent1 or indent2
                            _dump(v, indent, new_key, depth + 1)
                            temp[#temp + 1] = concat({space, tbktR})
                        else
                            temp[#temp + 1] = concat({space, keyBkt, eq, bktL, tbktR})
                        end
                    end
                end
            else
                if not excludeTypes or not excludeTypes[vType] then
                    if vType == "string" then
                        valtb[2] = string.gsub(v, "\"", "\\\"")
                        valtb[2] = string.gsub(v, "\0", "\\0")
                        v = concat(valtb)
                    end
                    temp[#temp + 1] = concat({space, keyBkt, eq, tostring(v), endMark})
                end
            end
        end
    end
    _dump(root, align1, empty, 1)
    temp[#temp + 1] = bktR
    return concat(temp, sep)
end

-- @brief 将表dump成字符串(便于人类阅读的格式,支持环状引用)
-- @param t table 表
-- @param max_depth int 最大深度,default=8
-- @return string dump成的字符串
function table.dump(t, max_depth)
    return table._dump(t, max_depth, {
        noAlignLine = true
    })
end

-- @brief 将表dump成一行字符串
-- @param t table 表
-- @param max_depth int 最大深度,default=8
-- @return string dump成的一行字符串
function table.tostring(t, max_depth)
    return table._dump(t, max_depth, {
        oneLine = true
    })
end

-- @brief 序列化一个值
-- @param value any 值
-- @return any 序列化后的数据(可直接转成bson)
function table.serialize(value)
    local data
    if type(value) ~= "table" then
        data = value
    elseif value.__type then
        -- class
        data = value:serialize()
        data.__t = value.__type.__name
    else
        data = {}
        local len = table.getn(value)
        if len > 0 then
            data.__array = {}
            for i = 1, len do
                data.__array[i] = table.serialize(value[i])
            end
        end

        for k, v in pairs(value) do
            if type(k) == "number" then
                if k > len then
                    local fields = data.__fields
                    if not fields then
                        fields = {}
                        data.__fields = fields
                    end
                    fields[#fields + 1] = {k, table.serialize(v)}
                end
            else
                data[k] = table.serialize(v)
            end
        end
    end
    return data
end

-- @brief 反序列化一个值
-- @param data any table.serialize返回的数据
-- @return any 反序列化后的表
function table.deserialize(data)
    local value
    if type(data) ~= "table" then
        value = data
    elseif data.__t then
        local typename = data.__t
        data.__t = nil
        local cls = _G[typename]
        value = Deserialize(cls, data)
    else
        value = {}

        local array = data.__array
        if array and #array > 0 then
            for i, v in ipairs(array) do
                value[i] = table.deserialize(v)
            end
        end

        local fields = data.__fields
        if fields then
            for _, f in ipairs(fields) do
                value[f[1]] = table.deserialize(f[2])
            end
        end

        data.__array = nil
        data.__fields = nil
        for k, vd in pairs(data) do
            value[k] = table.deserialize(vd)
        end
    end
    return value
end

-- @brief 根据键从表中获取值
-- @param tbl table 表
-- @param attr string 键
-- @return any 该键对于的值
-- @exception 分层键不存在时会报错
--[[! 示例
@code
    local val = table.getattr(tbl,"key")
    local val = table.getattr(tbl,"k1.k2.k3")
@endcode
]]
function table.getattr(tbl, attr)
    local attrs = type(attr) == "table" and attr or string.split(attr, ".")
    local root = tbl
    for i, attr in ipairs(attrs) do
        root = root[attr]
    end
    return root
end

-- @brief 判断表中是否有键
-- @param tbl table 表
-- @param attr string 键
-- @return bool 键是否存在
-- @return any 该键对于的值
--[[! 示例
@code
    local exist,val = table.hasattr(tbl,"key")
    local exist,val = table.hasattr(tbl,"k1.k2.k3")
@endcode
]]
function table.hasattr(tbl, attr)
    local attrs = type(attr) == "table" and attr or string.split(attr, ".")
    local root = tbl
    local len = #attrs
    for i, attr in ipairs(attrs) do
        root = root[attr]
        if i ~= len and type(root) ~= "table" then
            return false
        end
    end
    return true, root
end

-- @brief 向表中设置键值对
-- @param tbl table 表
-- @param attr string 键
-- @param val any 值
-- @return any 该键对应的旧值
--[[! 示例
@code
    table.setattr(tbl,"key",1)
    table.setattr(tbl,"k1.k2.k3","hi")
@endcode
]]
function table.setattr(tbl, attr, val)
    local attrs = type(attr) == "table" and attr or string.split(attr, ".")
    local lastkey = table.remove(attrs)
    local root = tbl
    for i, attr in ipairs(attrs) do
        if nil == root[attr] then
            root[attr] = {}
        end
        root = root[attr]
    end
    local oldval = root[lastkey]
    root[lastkey] = val
    return oldval
end

-- @brief 根据键从表中获取值
-- @param tbl table 表
-- @param attr string 键
-- @return any 该键对于的值,键不存在返回nil
--[[! 示例
@code
    local val = table.query(tbl,"key")
    local val = table.query(tbl,"k1.k2.k3")
@endcode
]]
function table.query(tbl, attr)
    local exist, value = table.hasattr(tbl, attr)
    if exist then
        return value
    else
        return nil
    end
end

-- @brief 判断是否为空表
-- @param tbl table 表
-- @return bool 是否为空表
function table.isempty(tbl)
    if cjson and cjson.null == tbl then -- int64:0x0
        return true
    end
    if not tbl or not next(tbl) then
        return true
    end
    return false
end

-- @brief 判断是否为空表(递归整个表,嵌套的空表，包括值为0/""的都是空值)
-- @param tbl table 表
-- @return bool 是否为空表
function table.isemptyx(tbl)
    if table.isempty(tbl) then
        return true
    end
    local isempty = true
    for k, v in pairs(tbl) do
        local typ = type(v)
        if typ == "table" then
            if not table.isemptyx(v) then
                isempty = false
            end
        elseif typ == "string" then
            if v ~= "" then
                isempty = false
            end
        elseif typ == "number" then
            if v ~= 0 and v ~= 0.0 then
                isempty = false
            end
        else
            isempty = false
        end
    end
    return isempty
end

-- @brief 将一个列表的所有元素都尾追到另一个列表
-- @param tbl1 table 被扩展的列表
-- @param tbl2 table 元素来源列表
-- @return table 扩展后的列表
function table.extend(tbl1, tbl2)
    for i, v in ipairs(tbl2) do
        tbl1[#tbl1 + 1] = v
    end
    return tbl1
end

-- @brief 将一个字典的所有键值对都更新到另一个字典
-- @param tbl1 table 被更新的字典
-- @param tbl2 table 键值对来源的字典
-- @param recursive bool true=递归更新
-- @return table 扩展后的字典
function table.update(tbl1, tbl2, recursive)
    for k, v in pairs(tbl2) do
        if type(v) == "table" then
            if recursive then
                tbl1[k] = tbl1[k] or {}
                table.update(tbl1[k], v)
            else
                tbl1[k] = v
            end
        else
            tbl1[k] = v
        end
    end
    return tbl1
end

-- @brief 将tbl2字典不存在于tabl1中的键值对更新到tbl1中
-- @param tbl1 table 被更新的字典
-- @param tbl2 table 键值对来源的字典
-- @return table 扩展后的字典
function table.append(tbl1, tbl2)
    for k, v in pairs(tbl2) do
        if not tbl1[k] then
            if type(v) == "table" then
                tbl1[k] = {}
                table.update(tbl1[k], v)
            else
                tbl1[k] = v
            end
        end
    end
end

-- @brief 统计一个表的元素个数
-- @param tbl table 表
-- @return int 元素个数
function table.count(tbl)
    local cnt = 0
    for k, v in pairs(tbl) do
        cnt = cnt + 1
    end
    return cnt
end

-- @brief 从表中删除特定值
-- @param t table 表
-- @param val any 删除的值
-- @param maxcnt int [optional] 最大删除个数,不指定则无限制
-- @return table 删除元素的所有键构成的列表
function table.delValue(t, val, maxcnt)
    local delkey = {}
    for k, v in pairs(t) do
        if v == val then
            if not maxcnt or #delkey < maxcnt then
                delkey[#delkey + 1] = k
            else
                break
            end
        end
    end
    for _, k in ipairs(delkey) do
        t[k] = nil
    end
    return delkey
end

-- @brief 从列表中删除元素
-- @param list table 列表
-- @param val any 删除的元素
-- @param maxcnt int [optional] 最大删除个数,不指定则无限制
-- @return table 删除元素的所有位置构成的列表
function table.removeValue(list, val, maxcnt)
    local len = #list
    maxcnt = maxcnt or len
    local delpos = {}
    for pos = len, 1, -1 do
        if list[pos] == val then
            table.remove(list, pos)
            table.insert(delpos, pos)
            if #delpos >= maxcnt then
                break
            end
        end
    end
    return delpos
end

-- @brief 将字典的所有元素的值构成列表
-- @param t table 字典
-- @return table 所有元素的值构成的列表
function table.tolist(t)
    local ret = {}
    for k, v in pairs(t) do
        ret[#ret + 1] = v
    end
    return ret
end

local function less_than(lhs, rhs)
    return lhs < rhs
end

-- @brief 在[1,\#t+1)区间找第一个>=val的位置
function table.lowerBound(t, val, cmp)
    cmp = cmp or less_than
    local len = #t
    local first, last = 1, len + 1
    while first < last do
        local pos = math.floor((last - first) / 2) + first
        if not cmp(t[pos], val) then
            last = pos
        else
            first = pos + 1
        end
    end
    if last > len then
        return nil
    else
        return last
    end
end

-- @brief 在[1,\#t+1)区间找第一个>val的位置
function table.upperBound(t, val, cmp)
    cmp = cmp or less_than
    local len = #t
    local first, last = 1, len + 1
    while first < last do
        local pos = math.floor((last - first) / 2) + first
        if cmp(val, t[pos]) then
            last = pos
        else
            first = pos + 1
        end
    end
    if last > len then
        return nil
    else
        return last
    end
end

-- @brief 判断两个对象是否相等
-- @param lhs any 对象1
-- @param rhs any 对象2
-- @return bool true--相等,false--不相等
function table.equal(lhs, rhs)
    if lhs == rhs then
        return true
    end
    if type(lhs) == "table" and type(rhs) == "table" then
        if table.count(lhs) ~= table.count(rhs) then
            return false
        end
        local issame = true
        for k, v in pairs(lhs) do
            if not table.equal(v, rhs[k]) then
                issame = false
                break
            end
        end
        return issame
    end
    return false
end

-- @brief 从列表中获取一个切片列表
-- @param list table 列表
-- @param b int 开始位置
-- @param e int opt 结束位置(包括这位置),如果为nil,则为b的值,而b变成1
-- @param step int opt=1 步长
-- @return table 新的切片列表
--[[! 示例
@code
local list = {1,2,3,4,5}
local new_list = table.slice(list,1,3)  -- {1,2,3}
local new_list = table.slice(list,1,5,2)  -- {1,3,5}
local new_list = table.slice(list,-1,-5,-1)  -- {5,4,3,2,1}
@endcode
]]
function table.slice(list, b, e, step)
    step = step or 1
    if not e then
        e = b
        b = 1
    end
    e = math.min(#list, e)
    local new_list = {}
    local len = #list
    local idx
    for i = b, e, step do
        idx = i >= 0 and i or len + i + 1
        new_list[#new_list + 1] = list[idx]
    end
    return new_list
end

-- @brief 将字典所有值构成一个集合
-- @param tbl table 字典
-- @param key string [optional] 使用指定key作为键
-- @return table 集合
function table.toset(tbl, key)
    tbl = tbl or {}
    local set = {}
    for i, v in ipairs(tbl) do
        if key and type(v) == "table" then
            set[assert(v[key])] = v
        else
            set[v] = true
        end
    end
    return set
end

-- @brief 计算2个集合的交集
-- @param set1 table 集合1
-- @param set2 table 集合2
-- @return table 交集
function table.intersectSet(set1, set2)
    local set = {}
    for k in pairs(set1) do
        if set2[k] then
            set[k] = true
        end
    end
    return set
end

-- @brief 计算2个集合的并集
-- @param set1 table 集合1
-- @param set2 table 集合2
-- @return table 并集
function table.unionSet(set1, set2)
    local set = {}
    for k in pairs(set1) do
        set[k] = true
    end
    for k in pairs(set2) do
        if not set1[k] then
            set[k] = true
        end
    end
    return set
end

-- @brief 计算2个集合的差集
-- @param set1 table 集合1
-- @param set2 table 集合2
-- @return table set1-set2
function table.diffSet(set1, set2)
    local ret = {}
    local set = table.intersectSet(set1, set2)
    for k in pairs(set1) do
        if not set[k] then
            ret[k] = true
        end
    end
    return ret
end

-- @brief 判断一个表是否为数组
-- @param tbl table 表
-- @return bool true--是数组,false--不是数组
function table.isarray(tbl)
    if type(tbl) ~= "table" then
        return false
    end
    local k = next(tbl)
    if k == nil then -- empty table
        return true
    end
    if k ~= 1 then
        return false
    else
        local len = #tbl
        k = next(tbl, len)
        if k ~= nil then
            return false
        end
        for i = 1, len do
            if tbl[i] == nil then
                return false
            end
        end
        return true
    end
end

function table.getn(t)
    local len = 0
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then
            break
        end

        len = len + 1
    end
    return len
end

function table.simplify(o, seen)
    local typ = type(o)
    if typ ~= "table" then
        return o
    end
    seen = seen or {}
    if seen[o] then
        return seen[o]
    end
    local newtable = {}
    seen[o] = newtable
    for k, v in pairs(o) do
        -- k = tostring(k)
        local tbl = table.simplify(v, seen)
        if type(tbl) ~= "table" then
            newtable[k] = tbl
        else
            for k1, v1 in pairs(tbl) do
                newtable[k .. "_" .. k1] = v1
            end
        end
    end
    return newtable
end

-- @brief 根据约束判断参数字典是否非法
-- @param args table 参数字典
-- @param descs table 约束表
-- @param strict bool [optional=false] 是否严格检查(严格检查时多余的参数也视为非法)
-- @return table|nil table--参数合法,经过约束处理后的新参数列表,nil--参数非法
-- @return string 第一个参数返回nil时才返回,表示参数非法原因
--[[! 示例
@code
local args,err = table.check(args,{
    sign = {type="string"},
    appid = {type="string"},
    roleid = {type="int"},
    image = {type="string",optional=true},
    money = {type="int|string"},
})
@endcode
]]
function table.check(args, descs, strict)
    local cjson = require "cjson"
    local new_args = {}
    for name, value in pairs(args) do
        local desc = descs[name]
        if desc then
            if desc.type == "number" or desc.type == "int" or desc.type == "float" or desc.type == "double" then
                local new_value = tonumber(value)
                if new_value == nil then
                    return nil, string.format("<%s,%s>: 非法类型,expect '%s',got '%s'", name, value, desc.type,
                        type(value))
                end
                if desc.min and desc.min > new_value then
                    return nil, string.format("<%s,%s>: 小于最小值(%s)", name, value, desc.min)
                end
                if desc.max and desc.max < new_value then
                    return nil, string.format("<%s,%s>: 大于最大值(%s)", name, value, desc.max)
                end
                if desc.type == "int" then
                    local int_value = math.floor(new_value)
                    if int_value ~= new_value then
                        return nil, string.format("<%s,%s>: 非法类型,expect 'int',got 'float'", name, value)
                    end
                    new_value = int_value
                end
                new_args[name] = new_value
            elseif desc.type == "bool" or desc.type == "boolean" then
                local new_value
                if value == true or value == 1 or value == "true" or value == "on" or value == "yes" then
                    new_value = true
                else
                    new_value = false
                end
                new_args[name] = new_value
            elseif desc.type == "json" then
                local isok, new_value = pcall(cjson.decode, value)
                if not isok then
                    return nil, string.format("<%s,%s>: 非法类型,expect '%s',got '%s'", name, value, desc.type,
                        type(value))
                end
                new_args[name] = new_value
            else
                local types = string.split(desc.type, "|")
                if not table.find(types, type(value)) then
                    return nil, string.format("<%s,%s>: 非法类型,expect '%s',got '%s'", name, value, desc.type,
                        type(value))
                end
                new_args[name] = value
            end
        else
            if strict then
                return nil, string.format("<%s,%s>: 多余参数", name, value)
            else
                new_args[name] = value
            end
        end
        descs[name] = nil
    end
    if next(descs) then
        for name, desc in pairs(descs) do
            if not desc.optional then
                return nil, string.format("缺少参数: %s", name)
            else
                new_args[name] = desc.default
            end
        end
    end
    return new_args, nil
end

-- @brief 从列表中等概率选择一个值
-- @param list table 列表
-- @return any 命中的值
-- @return int 命中值的位置
function table.choose(list)
    local len = #list
    assert(len > 0, "list length need > 0")
    local pos = math.random(1, len)
    return list[pos], pos
end

-- @brief 从列表中等概率选择N个值
-- @param list table 列表
-- @return table 命中值列表
function table.chooseN(list, N)
    local idxList = {}
    local len = #list
    for i = 1, len do
        idxList[#idxList + 1] = i
    end
    local newList = {}
    local pos
    N = math.min(N, len)
    while N > 0 do
        pos = math.random(1, #idxList)
        newList[#newList + 1] = list[idxList[pos]]
        table.remove(idxList, pos)
        N = N - 1
        if #idxList == 0 then
            break
        end
    end
    return newList
end

-- @brief 根据字典的键来排序(键为字符串则用字典序排),排完后再拼接成字符串
-- @param dict table 字典
-- @param join_str string [optional="&"] 拼接时用的连接字符
-- @param exclude_keys table [optional={}] 排除的键
-- @param exclude_values table [optional={}] 排除的值
-- @return string 排序+拼接后的最终字符串
--[[! 示例
@code
local dict = {k1 = 1,k2 = 2}
local str = table.ksort(dict,"&") => k1=1&k2=2
@endcode
]]
function table.ksort(dict, join_str, exclude_keys, exclude_values)
    join_str = join_str or "&"
    exclude_keys = exclude_keys or {}
    exclude_values = exclude_values or {}
    local list = {}
    for k, v in pairs(dict) do
        if (not exclude_keys or not exclude_keys[k]) and (not exclude_values or not exclude_values[v]) then
            table.insert(list, {k, v})
        end
    end
    table.sort(list, function(lhs, rhs)
        return lhs[1] < rhs[1]
    end)
    local list2 = {}
    for i, item in ipairs(list) do
        table.insert(list2, string.format("%s=%s", item[1], item[2]))
    end
    return table.concat(list2, join_str)
end

-- @brief 清空表
-- @param tbl table 表
function table.clear(tbl)
    for k, v in pairs(tbl) do
        rawset(tbl, k, nil)
    end
end

-- @brief 以指定元素重复若干次生成一个列表
-- @param elem any 元素
-- @param count int 重复次数
-- @return table 列表
function table.rep(elem, count)
    local list = {}
    for i = 1, count do
        list[#list + 1] = elem
    end
    return list
end

-- @brief 根据指定范围[from,to]生成整数列表
-- @param from int 起始值
-- @param to int 终止值
-- @return table 整数列表
function table.range(from, to)
    local list = {}
    for v = from, to do
        list[#list + 1] = v
    end
    return list
end

-- @brief 从表格中查找指定值，返回其索引，如果没找到返回nil
-- @param array table 表格
-- @param value mixed 要查找的值
-- @param begin integer 起始索引值,默认为1
-- @return integer|nil 找到的位置,没找到返回nil
function table.indexof(array, value, begin)
    for i = begin or 1, #array do
        if array[i] == value then
            return i
        end
    end
    return nil
end

-- @brief 从表格中查找指定值，返回其 key，如果没找到返回 nil
-- @param hashtable table 表格
-- @param value mixed 要查找的值
-- @return 该值对应的 key
function table.keyof(hashtable, value)
    for k, v in pairs(hashtable) do
        if v == value then
            return k
        end
    end
    return nil
end

-- @brief 排序列表前n个元素
-- @param n int 前n个元素
-- @param tbl table 列表
-- @param cmp func 比较函数(同table.sort)
-- @return table 排序后的前n个元素构成的新列表
function table.sortN(n, tbl, cmp)
    local ret = {}
    local len = 0
    local function bubble(pos, v)
        while pos > 1 do
            if cmp(v, ret[pos - 1]) then
                ret[pos] = ret[pos - 1]
                pos = pos - 1
            else
                break
            end
        end
        ret[pos] = v
    end
    for k, v in pairs(tbl) do
        if len < n then
            len = len + 1
            bubble(len, v)
        elseif cmp(v, ret[len]) then
            bubble(len, v)
        end
    end
    return ret
end

-- @brief 反转数组
-- @param list table 数组
function table.reverse(list)
    local length = #list
    local temp
    for i = 1, length / 2 do
        temp = list[i]
        list[i] = list[length - i + 1]
        list[length - i + 1] = temp
    end
end

-- @brief 返回字典唯一值列表
-- @param t table 数组/字典
-- @param func function [optional] nil=值直接作为是否唯一判定标准,否则=func(v)返回值作为是否唯一判定标准
-- @return list 唯一值列表
function table.unique(t, func)
    local check = {}
    local n = {}
    local idx = 1
    local unique_value
    for k, v in pairs(t) do
        unique_value = func and func(v) or v
        if not check[unique_value] then
            n[idx] = v
            idx = idx + 1
            check[unique_value] = true
        end
    end
    return n
end

-- @brief 返回字典唯一值字典
-- @param t table 数组/字典
-- @param func function [optional] nil=值直接作为是否唯一判定标准,否则=func(v)返回值作为是否唯一判定标准
-- @return list 唯一值字典
function table.uniqueDict(t, func)
    local check = {}
    local n = {}
    local unique_value
    for k, v in pairs(t) do
        unique_value = func and func(v) or v
        if not check[unique_value] then
            n[k] = v
            check[unique_value] = true
        end
    end
    return n
end

function table.new(narr, nrec)
    return {}
end

local ok, lutil = pcall(require, "lutil")
if ok then
    table.new = lutil.table_new
    table.copy = lutil.table_copy
    table.update = lutil.table_update
    table.deepcopy = function(o)
        if Cfg and Cfg.isCfg(o) then
            return deepcopy(o)
        end
        return lutil.table_deepcopy(o)
    end
end
