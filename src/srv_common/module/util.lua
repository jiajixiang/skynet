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

function table.dump(t, depth, name)
    if type(t) ~= "table" then
        return tostring(t)
    end
    depth = depth or 0
    local max_depth = 5
    name = name or ""
    local cache = {
        [t] = "."
    }
    local function _dump(t, depth, name)
        local temp = {}
        local bracket_space = string.rep(" ", depth * 2)
        local space = string.rep(" ", (depth + 1) * 2)
        table.insert(temp, "{")
        if depth < max_depth then
            for k, v in pairs(t) do
                local key = tostring(k)
                if type(k) == "number" then
                    key = "[" .. key .. "]"
                end
                local value
                if cache[v] then
                    value = cache[v]
                elseif type(v) == "table" then
                    local new_key = name .. "." .. key
                    cache[v] = new_key
                    value = _dump(v, depth + 1, new_key)
                else
                    if type(v) == "string" then
                        v = "\"" .. string.gsub(v, "\"", "\\\"") .. "\""
                    end
                    value = tostring(v)
                end
                table.insert(temp, space .. key .. " = " .. value)
            end
        else
            table.insert(temp, space .. "...")
        end
        table.insert(temp, bracket_space .. "}")
        return table.concat(temp, "\n")
    end
    return _dump(t, depth, name)
end

function table.ksort(dict, join_str, exclude_keys, exclude_values)
    join_str = join_str or "&"
    exclude_keys = exclude_keys or {}
    exclude_values = exclude_values or {
        [""] = true
    }
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

local function get_type_first_print(t)
    local str = type(t)
    return string.upper(string.sub(str, 1, 1)) .. ":"
end

function util.dump_table(t, prefix, indent_input, print)
    local indent = indent_input
    if indent_input == nil then
        indent = 1
    end

    if print == nil then
        print = _G["print"]
    end

    local p = nil

    local formatting = string.rep("    ", indent)
    if prefix ~= nil then
        formatting = prefix .. formatting
    end

    if t == nil then
        print(formatting .. " nil")
        return
    end

    if type(t) ~= "table" then
        print(formatting .. get_type_first_print(t) .. tostring(t))
        return
    end

    local output_count = 0
    for k, v in pairs(t) do
        local str_k = get_type_first_print(k)
        if type(v) == "table" then

            print(formatting .. str_k .. k .. " -> ")

            util.dump_table(v, prefix, indent + 1, print)
        else
            print(formatting .. str_k .. k .. " -> " .. get_type_first_print(v) .. tostring(v))
        end
        output_count = output_count + 1
    end

    if output_count == 0 then
        print(formatting .. " {}")
    end
end

---@brief 获取表的所有键
---@param t table 表
---@return table 所有键构成的列表
function table.keys(t)
    local ret = {}
    for k, v in pairs(t) do
        ret[#ret + 1] = k
    end
    return ret
end

-- $Id$--__auto_local__start--
local string = string
local table = table
local math = math
local io = io
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
-- __auto_local__end--

-- 运行一个其他模块的函数
function RunFun(Obj, Fun, arg)
    if type(Obj) == "string" then
        local TmpModule = Import(Obj)
        if not TmpModule then
            return nil
        end
        -- print(Obj, Fun,TmpModule,arg)
        local Args = unpack(arg)
        if type(Fun) == "string" then
            local RealFun = TmpModule[Fun]
            if RealFun then
                return RealFun(Args)
            else
                return nil
            end
            -- 直接注册一个function可能会导致不能在线更新
        elseif type(Fun) == "function" then
            return Fun(unpack(arg))
        end
    elseif type(Obj) == "table" then
        if type(Fun) == "function" then
            return Fun(Obj, unpack(arg))
        else
            return Obj[Fun](Obj, unpack(arg))
        end
    else
        return nil
    end
end

function FormatSerialize(Object)
    local function ConvSimpleType(v)
        if type(v) == "string" then
            return string.format("%q", v)
        end
        return tostring(v)
    end

    local function RealFun(Object, Depth)
        -- TODO: gxzou 循环引用没有处理？
        Depth = Depth or 0
        Depth = Depth + 1
        assert(Depth < 20, "too long Depth to serialize")

        if type(Object) == 'table' then
            -- if Object.__ClassType then return "<Object>" end
            local Ret = {}
            table.insert(Ret, '{\n')
            for k, v in pairs(Object) do
                -- print ("serialize:", k, v)
                local _k = ConvSimpleType(k)
                if _k == nil then
                    error("key type error: " .. type(k))
                end
                table.insert(Ret, '[' .. _k .. ']')
                table.insert(Ret, '=')
                table.insert(Ret, RealFun(v, Depth))
                table.insert(Ret, ',\n')
            end
            table.insert(Ret, '}\n')
            return table.concat(Ret)
        else
            return ConvSimpleType(Object)
        end
    end

    return RealFun(Object)
end

function _Serialize(Object)
    local function ConvSimpleType(v)
        if type(v) == "string" then
            return string.format("%q", v)
        end
        return tostring(v)
    end

    local function RealFun(Object, Depth)
        -- TODO: gxzou 循环引用没有处理？
        Depth = Depth or 0
        Depth = Depth + 1
        assert(Depth < 20, "too long Depth to serialize")

        if type(Object) == 'table' then
            -- if Object.__ClassType then return "<Object>" end
            local Ret = {}
            table.insert(Ret, '{')
            for k, v in pairs(Object) do
                -- print ("serialize:", k, v)
                local _k = ConvSimpleType(k)
                if _k == nil then
                    error("key type error: " .. type(k))
                end
                table.insert(Ret, '[' .. _k .. ']')
                table.insert(Ret, '=')
                table.insert(Ret, RealFun(v, Depth))
                table.insert(Ret, ',')
            end
            table.insert(Ret, '}')
            return table.concat(Ret)
        else
            return ConvSimpleType(Object)
        end
    end

    return RealFun(Object)
end

-- engine.SerializeSaveData接口会加入一些换行符和制表符，让序列化结果比engine.Serialize稍微好看点
Serialize = _Serialize
if engine then
    Serialize = engine.Serialize
end

-- Data是序列化的数据(字符串)
function UnSerialize(Data)
    return assert(loadstring("return " .. Data))()
end

-- 设置一个Table为只读
-- Sample: Wizard = ReadOnly{"gm001","gm002","gm003"}
function ReadOnly(t)
    local proxy = {}
    local mt = { -- create metatable
        __index = t,
        __newindex = function(t, k, v)
            error("attempt to update a read-only table", 2)
        end
    }
    setmetatable(proxy, mt)
    return proxy
end

function Null(...)
end

function Copy(src, rel)
    local rel = rel or {}
    if type(src) ~= "table" then
        return rel
    end
    for k, v in pairs(src) do
        rel[k] = v
    end
    return rel
end

function ArrayCopy(src)
    local ret = {}
    if type(src) ~= "table" then
        return ret
    end
    for k, v in ipairs(src) do
        ret[k] = v
    end
    return ret
end

function DeepCopy(src, quiet)
    if type(src) ~= "table" then
        return src
    end
    local cache = {}
    local function clone_table(t, level)
        if not level then
            level = 0
        end

        if level > 20 then
            if not quiet then
                error("table clone failed, " .. "source table is too deep!")
            else
                return t
            end
        end

        local k, v
        local rel = {}
        for k, v in pairs(t) do
            -- if k == "Name" then print(k, tostring(v)) end
            if type(v) == "table" then
                if cache[v] then
                    rel[k] = cache[v]
                else
                    rel[k] = clone_table(v, level + 1)
                    cache[v] = rel[k]
                end
            else
                rel[k] = v
            end
        end
        setmetatable(rel, getmetatable(t))
        return rel
    end
    return clone_table(src)
end

-- touch一个文件出来，如果没有相关路径，会自动创建
function Touch(PathFile)
    if posix.stat(PathFile) then
        return
    end

    local Start = 1
    while 1 do
        local TmpStart, TmpEnd = string.find(PathFile, "%/", Start)
        if TmpStart and TmpEnd then
            local Path = string.sub(PathFile, 1, TmpEnd)
            if not posix.stat(Path) then
                posix.mkdir(Path)
            end
            Start = TmpEnd + 1
        else
            break
        end
    end
    if not posix.stat(PathFile) then
        local fh = io.open(PathFile, "a+")
        fh:close()
    end
end

-- 编译成binary的结构
BinPath = "../binary/"
function DumpFile(PathFile, ToPathFile)
    local s1 = posix.stat(PathFile)
    local s2 = posix.stat(ToPathFile)
    if s1 and s2 then
        if s2.mtime >= s1.mtime then
            return
        end
    end
    -- print("compiling ", PathFile)

    local fh = io.open(PathFile)

    local FileData = fh:read("*a")

    -- 不再需要
    -- FileData = string.gsub(FileData, '([%(%s%,])__FILE__', 
    --	'%1"'..PathFile..'"')

    local func, err = loadstring(FileData, PathFile)
    assert(func, err)

    if not ToPathFile then
        ToPathFile = BinPath .. PathFile
    end

    -- 暂时不用改名
    -- ToPathFile = string.gsub(ToPathFile, "%.[%w_-]+$", ".bin")
    Touch(ToPathFile)
    local Handler = io.open(ToPathFile, "w+")
    if not Handler then
        print("no such file", ToPathFile)
        return
    end
    Handler:write(string.dump(func))
    Handler:close()
end

-- 挖出所有扩展名为EndSwith的文件
function ListTree(Path, EndSwith, Exclude)
    assert(Path)

    local Res = {}
    local ExcludeDirs = {".", "..", ".svn"}
    array.merge(ExcludeDirs, Exclude or {})

    for file in posix.files(Path) do
        if not table.member_key(ExcludeDirs, file) then
            local PathFile
            if not string.endswith(Path, "/") then
                PathFile = Path .. "/" .. file
            else
                PathFile = Path .. file
            end
            local filetype = posix.stat(PathFile).type

            if filetype == "directory" then
                for k, v in pairs(ListTree(PathFile, EndSwith, Exclude)) do
                    table.insert(Res, v)
                end

            elseif filetype == "regular" then
                if string.endswith(PathFile, EndSwith) then
                    if string.beginswith(PathFile, "./") then
                        PathFile = string.sub(PathFile, 3)
                    end
                    table.insert(Res, PathFile)
                end
            end
        end
    end

    return Res
end

-- should only use in initializing phase
-- such as ciritcal error happen when loading network protocol 
function Exit(Code)
end

-- group object o and function f together to make functor
function Functor(o, f)
    local o = o or {}
    local mt = getmetatable(o) or {}
    mt.__call = f or print
    setmetatable(o, mt)
    return o
end

-- note: i do not check validity of input arguments, 
-- do it yourself before you call the following function. 

-- get element count of table
function Getn(t)
    local n = 0
    for _, _ in pairs(t) do
        n = n + 1
    end
    return n
end

-- copy and transform
function TranCopy(t, f)
    local o = {}
    for k, v in pairs(t) do
        o[k] = f(k, v)
    end
    return o
end
-- modify the table elements
function Transform(t, f)
    for k, v in pairs(t) do
        t[k] = f(k, v)
    end
    return t
end

function ForPair(t, f)
    local f = f or print
    for i, v in pairs(t) do
        f(i, v)
    end
end

function ForKey(t, f)
    local f = f or print
    for i in pairs(t) do
        f(i)
    end
end

function ForValue(t, f)
    local f = f or print
    for _, v in pairs(t) do
        f(v)
    end
end

function FindAnyValue(t, f)
    local f = f or print
    for _, v in pairs(t) do
        if f(v) then
            return v
        end
    end
end

-- return the hast-table
function FiltT(t, f)
    local r = {}
    for i, v in pairs(t) do
        if f(i, v) then
            r[i] = v
        end
    end
    return r
end

-- return the array
-- conver the hash-table to array if argumen f is nil
function FiltA(t, f)
    local r = {}
    local f = f or function(i, v)
        return true
    end
    for i, v in pairs(t) do
        if f(i, v) then
            table.insert(r, v)
        end
    end
    return r
end

function Map(t, f)
    local r, x = {}, nil
    for _, v in pairs(t) do
        x = f(v)
        if x then
            table.insert(r, x)
        end
    end
    return r
end

-- function : Assign
-- 将Sour中成员的值赋值给Dest中相应成员
function Assign(Dest, Sour, Recurse, Clear)
    assert(type(Dest) == "table" and type(Sour) == "table")

    if Sour == nil then
        Sour = Dest
        Dest = {}
    end

    if Clear then
        for k, v in pairs(Dest) do
            Dest[k] = nil
        end
    end

    Visited = {}

    local function _Helper(Dest, Sour, Visited)
        for k, v in pairs(Sour) do
            if type(v) == "table" then
                if Recurse then
                    local WasVisited = false
                    for _, t in ipairs(Visited) do
                        if t == v then
                            WasVisited = true
                            break
                        end
                    end

                    if not WasVisited then
                        Dest[k] = Dest[k] or {}
                        table.insert(Visited, v)
                        _Helper(Dest[k], v, Visited)
                    end
                end
            else
                Dest[k] = v
            end
        end
    end

    _Helper(Dest, Sour, Visited)
end

function StrToDigit(strftime)
end

-- input {{"1","一",}, {"2","二"}, {"3","三"}}
-- output example as "一2三"
-- 组合函数
function Comb(src)
    local function concat(a, b)
        local tbl = {}
        for _, v1 in pairs(a) do
            for _, v2 in pairs(b) do
                table.insert(tbl, string.format("%s%s", v1, v2))
            end
        end
        return tbl
    end
    local tbl = src[1]
    for k = 2, #src do
        tbl = concat(tbl, src[k])
    end
    return tbl
end

local function Sort(x, y)
    if x <= y then
        return x, y
    else
        return y, x
    end
end

function InRectangle(x0, y0, x1, y1, x2, y2)
    x1, x2 = Sort(x1, x2)
    y1, y2 = Sort(y1, y2)

    return x1 <= x0 and x0 <= x2 and y1 <= y0 and y0 <= y2
end

-- is Seta subset of Setb ?
function IsArraySubSet(Seta, Setb)
    for _, v in pairs(Seta) do
        if not table.member_key(Setb, v) then
            return false
        end
    end
    return true
end

function ArrayFiltoutAny(Seta, Setb)
    for _, v in pairs(Seta) do
        if not table.member_key(Setb, v) then
            return v
        end
    end
    return nil
end

-- 将生成的内容插入到 "autogen-bein" 和 "autogen-end" 之间
function AutoGenSave(File, Data)
    local function Repl(Begin, End)
        return Begin .. Data .. End
    end

    local Content
    local rf = io.open(File, "r")
    if rf then -- File exists
        Content = rf:read("*a")
        rf:close()
    end

    if Content then
        -- see lua reference about string.gsub 
        -- If repl is a string, then its value is used for replacement. 
        -- The character % works as an escape character.
        -- the statement below will discard the "%"
        -- Data, sub = string.gsub (Content, "(%-%-autogen%-begin).-(%-%-autogen%-end)", "%1"..Data.."%2")

        local sub
        Data, sub = string.gsub(Content, "(%-%-autogen%-begin).-(%-%-autogen%-end)", Repl)
        -- assert (sub == 1, "must insert into the file:"..File)
        if sub == 0 then
            print("Warning:", File .. " has exists and has not autogen-region. just skip it.")
        end
    else -- File does not exist
        Data = "--autogen-begin" .. Data .. "--autogen-end"
    end

    local File = assert(io.open(File, "w"))
    File:write(Data)
    File:flush()
    File:close()
end

local ID_OFFSET = 10000
function GenId(Index)
    return Index * ID_OFFSET + HostId
end

-- Point: {X = , Y= ,}
-- Convex: PointList { [1] = Piont , ... } anticlockwise
-- 0: Out 
-- 1: In 
function ConvexPointRelation(Point, Convex)
    local ConvexN = #Convex
    if ConvexN < 3 then
        return nil
    end
    for i = 1, ConvexN do
        local P1 = Convex[i]
        local i2 = (i >= ConvexN) and 1 or (i + 1)
        local P2 = Convex[i2]
        -- P2 - P1
        local V2 = {
            X = P2.X - P1.X,
            Y = P2.Y - P1.Y
        }

        -- Point - P1 
        local V1 = {
            X = Point.X - P1.X,
            Y = Point.Y - P1.Y
        }

        -- Cross Product
        local Cross = V1.X * V2.Y - V2.X * V1.Y

        if Cross < 0 then
            return 0
        end
    end
    return 1
end

-- For array repersent of point
-- Point: { X, Y }
-- Convex: PointList { [1] = Piont , ... } anticlockwise
-- 0: Out 
-- 1: In 
function ConvexPointRelation2(Point, Convex)
    local ConvexN = #Convex
    if ConvexN < 3 then
        return nil
    end
    for i = 1, ConvexN do
        local P1 = Convex[i]
        local i2 = (i >= ConvexN) and 1 or (i + 1)
        local P2 = Convex[i2]
        -- P2 - P1
        local V2 = {P2[1] - P1[1], P2[2] - P1[2]}

        -- Point - P1 
        local V1 = {Point[1] - P1[1], Point[2] - P1[2]}

        -- Cross Product
        local Cross = V1[1] * V2[2] - V2[1] * V1[2]

        if Cross < 0 then
            return 0
        end
    end
    return 1
end

----------------------JSON start---------------------------
local function EncodeString(s)
    s = string.gsub(s, '\\', '\\\\')
    s = string.gsub(s, '"', '\\"')
    s = string.gsub(s, "'", "\\'")
    s = string.gsub(s, '\n', '\\n')
    s = string.gsub(s, '\t', '\\t')
    return s
end

function JSONEncode(Field, Depth)
    Depth = (Depth or 0) + 1
    assert((Depth < 20), "JSONEncode too deep")

    assert(not IsFunc(Field))

    local JSONNull = "null"

    if Field == nil then
        return JSONNull
    end

    if IsString(Field) then
        return string.format('"%s"', EncodeString(Field))
    end

    if IsNumber(Field) or IsBoolean(Field) then
        return tostring(Field)
    end

    if IsTable(Field) then
        local IsArray = IsArray(Field)
        local RetVal = ""
        if IsArray then
            for idx = 1, table.getn(Field) do
                if RetVal == "" then
                    RetVal = JSONEncode(Field[idx], Depth)
                else
                    RetVal = string.format("%s,%s", RetVal, JSONEncode(Field[idx], Depth))
                end
            end
        else
            for k, v in pairs(Field) do
                assert((not IsTable(k)) and (not IsFunc(k)), "JSONEncode unsupported key type")

                local EncodeKey = JSONEncode(k, Depth)
                local EncodeVal = JSONEncode(v, Depth)
                if RetVal == "" then
                    RetVal = string.format("%s:%s", EncodeKey, EncodeVal)
                else
                    RetVal = string.format("%s,%s:%s", RetVal, EncodeKey, EncodeVal)
                end
            end
        end

        if IsArray then
            return string.format("[%s]", RetVal)
        else
            return string.format("{%s}", RetVal)
        end
    end

    assert(false, "unsupported type")
end
-------------------------------JSON end------------------------

--------------------修改存档一些接口--------------------
-- 包含魔字符的字符串，是不能直接作为pattern使用，如[] -> %[%]
local MagicChar = {"(", ")", ".", --[["%",]] "+", "-", "*", "?", "[", "]", "^", "$"}
local function ConvertToPattern(String)
    for _, Char in pairs(MagicChar) do
        local Pattern = "%" .. Char
        local Repl = "%%" .. Char
        String = string.gsub(String, Pattern, Repl)
    end
    return String
end

local function GetDataSIds(Data)
    local SIds = {}
    for SIdTerm, _ in string.gmatch(Data, "%[\"SId\"%].-,") do
        local SId = string.match(SIdTerm, "(%d+)")
        table.insert(SIds, SId)
    end
    return SIds
end

local function ModifySummonDataSId(Data)
    local OldSummonData = string.match(Data, "%[\"summon\"%]=.-\n")
    local SIds = GetDataSIds(OldSummonData)
    local SummonSIdMgr = Import("char/summon_sid_mgr.lua")
    local NewSummonData = OldSummonData
    for _, SId in pairs(SIds) do
        local NewSId = SummonSIdMgr.GetSId()
        NewSummonData = string.gsub(NewSummonData, SId, NewSId) -- 不在Data直接替换，因为可能会替换Item的SId
    end
    Data = string.gsub(Data, ConvertToPattern(OldSummonData), NewSummonData)
    return Data
end

local function ModifyItemDataSId(Data)
    local OldItemData = string.match(Data, "%[\"item\"%]=.-\n")
    local SIds = GetDataSIds(OldItemData)
    local NewItemData = OldItemData
    local ItemSIdMgr = Import("char/item_sid_mgr.lua")
    for _, SId in pairs(SIds) do
        local NewSId = ItemSIdMgr.GetSId()
        NewItemData = string.gsub(NewItemData, SId, NewSId)
    end
    Data = string.gsub(Data, ConvertToPattern(OldItemData), NewItemData)
    return Data
end

local function ModifyUserName(Data, NewName)
    local NameData = string.match(Data, "%s%[\"Name\"%]=\".-\",\n")
    local OldName = string.match(NameData, "%s%[\"Name\"%]=\"(.-)\",\n")
    local NewNameData = string.gsub(NameData, OldName, NewName)
    Data = string.gsub(Data, ConvertToPattern(NameData), NewNameData)
    return Data
end

local function ModifyUserId(Data, SrcUserId, NewUserId)
    Data = string.gsub(Data, string.format("=%s,", tostring(SrcUserId)), string.format("=%s,", tostring(NewUserId)))
    return Data
end

local function ModifyUserSchool(Data, NewSchool)
    local SchoolData = string.match(Data, "%[\"School\"%]=.-,\n")
    local OldSchool = string.match(SchoolData, "%[\"School\"%]=(.-),\n")
    local NewSchoolData = string.gsub(SchoolData, OldSchool, NewSchool)
    Data = string.gsub(Data, ConvertToPattern(SchoolData), NewSchoolData)
    return Data
end

local function ModifyUserIcon(Data, NewIcon)
    local IconData = string.match(Data, "%[\"Icon\"%]=.-,\n")
    local OldIcon = string.match(IconData, "%[\"Icon\"%]=(.-),\n")
    local NewIconData = string.gsub(IconData, OldIcon, NewIcon)
    Data = string.gsub(Data, ConvertToPattern(IconData), NewIconData)
    return Data
end

-- 根据已有的玩家存档数据，为新的UserId产生一份存档数据
-- 1、修改召唤兽ownerid，物品BindId之类
-- 2、item的SId
-- 3、summon的SId
function GenNewDBFromExampleDB(Data, SrcUserId, NewUserId, NewUserName)
    if not Data then
        return
    end
    if SrcUserId and NewUserId then
        Data = ModifyUserId(Data, SrcUserId, NewUserId)
    end
    Data = ModifySummonDataSId(Data)
    Data = ModifyItemDataSId(Data)
    if NewUserName then
        Data = ModifyUserName(Data, NewUserName)
    end
    return Data
end

-- 位操作的简单包装
-- 简单容错，此文件会被很多读表程序用到
local bit = bit or {}
local bnot, band, bxor, bor, rshift, lshift = bit.bnot, bit.band, bit.bxor, bit.bor, bit.rshift, bit.lshift
--
-- MASK1(2, 1) = 0...0110
--
function MASK1(n, p)
    return lshift(bnot(lshift(bnot(0), n)), p)
end

--
-- MASK0(2, 1) = 1...1001
--
function MASK0(n, p)
    return bnot(MASK1(n, p))
end

function BitAnd(a, b)
    return band(a, b)
end

function BitOr(a, b)
    return bor(a, b)
end

function BitXor(a, b)
    return bxor(a, b)
end

function BitNot(a)
    return bnot(a)
end

-- eg:
-- Str : "(1 + (Grade - 1)*0.1)*1000"
-- PatternTbl : {Grade=100}	-- 可以有多个替换
-- return 10900
function StrParser(Str, PatternTbl)
    for Pattern, Replacer in pairs(PatternTbl) do
        Str = string.gsub(Str, Pattern, tostring(Replacer))
    end
    local FuncStr = "return " .. Str
    local func = loadstring(FuncStr)
    assert(func, string.format("parse error! src=%s,dst=%s", Str, FuncStr))
    return func()
end

function IsInternalClient(vfd)
    local Ip = network.GetVfdIp(vfd) or ""
    return string.find(Ip, "^192%.168")
end

function EncodeScenePosURL(Desc, Scene, x, y)
    return string.format('<pos scene=%d x=%d y=%d>%s</pos>', Scene, x, y, Desc)
end

--------------------------------------------------------

local log_dir = GAME.getLogBasePath()
local curTimeStamp = nil
timeLogDir = nil
local timeRange = 4

local function checkValidTimeStamp(time_info)
    return (curTimeStamp.year == time_info.year and curTimeStamp.month == time_info.month and curTimeStamp.day ==
               time_info.day)
end

local function getDirByTimeStamp(timeStamp)
    if string.sub(log_dir, 1, 1) == "/" then
        return string.format("%s/%s_%s_%s", log_dir, timeStamp.year, timeStamp.month, timeStamp.day)
    else
        return string.format("%s/%s_%s_%s", log_dir, timeStamp.year, timeStamp.month, timeStamp.day)
    end
end

local LOG_MAX_LEN = 4048 - 10
function logging(file_name, str)
    local time_info = os.date("*t", os.time())
    local hour = time_info.hour
    local min = time_info.min
    local sec = time_info.sec
    time_info.hour = 0
    time_info.min = 0
    time_info.sec = 0
    if (not curTimeStamp) or (not checkValidTimeStamp(time_info)) then
        curTimeStamp = time_info
        timeLogDir = getDirByTimeStamp(curTimeStamp)
        lutil.touchDir(timeLogDir)
    end
    str = string.format("[%s-%02d-%02d %02d:%02d:%02d]%s\n", time_info.year, time_info.month, time_info.day, hour, min,
        sec, str)
    local len = string.len(str)
    if len > LOG_MAX_LEN then
        str = string.sub(str, 1, LOG_MAX_LEN)
        str = string.format("%s\n", str)
        len = string.len(str)
    end
    lutil.logging(string.format("%s/%s", timeLogDir, file_name), str, len)
end

local startUTime = nil
function getUTime()
    if not startUTime then
        startUTime = lutil.getUTime()
    end
    return (lutil.getUTime() - startUTime)
end

local function unicode_to_utf8(convertStr)
    if type(convertStr) ~= "string" then
        return convertStr
    end
    local resultStr = ""
    local i = 1
    while true do
        local num1 = string.byte(convertStr, i)
        local unicode
        if num1 ~= nil and string.sub(convertStr, i, i + 1) == "\\u" then
            unicode = tonumber("0x" .. string.sub(convertStr, i + 2, i + 5))
            i = i + 6
        elseif num1 ~= nil then
            unicode = num1
            i = i + 1
        else
            break
        end
        if unicode <= 0x007f then
            resultStr = resultStr .. string.char(BitAnd(unicode, 0x7f))
        elseif unicode >= 0x0080 and unicode <= 0x07ff then
            resultStr = resultStr .. string.char(BitOr(0xc0, BitAnd(rshift(unicode, 6), 0x1f)))
            resultStr = resultStr .. string.char(BitOr(0x80, BitAnd(unicode, 0x3f)))
        elseif unicode >= 0x0800 and unicode <= 0xffff then
            resultStr = resultStr .. string.char(BitOr(0xe0, BitAnd(rshift(unicode, 12), 0x0f)))
            resultStr = resultStr .. string.char(BitOr(0x80, BitAnd(rshift(unicode, 6), 0x3f)))
            resultStr = resultStr .. string.char(BitOr(0x80, BitAnd(unicode, 0x3f)))
        end
    end
    resultStr = resultStr .. '\0'
    return resultStr
end

function safe_unicode_to_utf8(data)
    local ret, str = pcall(unicode_to_utf8, data)
    if ret then
        return str
    end
end

function __init__()
end

