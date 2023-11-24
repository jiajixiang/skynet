---@details
---1.支持热更新，支持父类热更新直接反应到子类,不支持热更删除的成员函数，可以写成空函数来屏蔽\n
---2.支持所有lua元方法,并且元方法支持热更(注意元方法不支持继承)\n
---3.支持继承userdata,这个高级用法可以允许你继承C++对象/C#对象\n
---@see https://blog.codingnow.com/cloud/LuaOO
--[[! 示例
@code
    local Point = class("Point")
    function Point:ctor(x,y,z)
        self.x = x
        self.y = y
        self.z = z
    end

    local LuaVector3 = class("LuaVector3",Point)

    function LuaVector3:ctor(x,y,z)
        LuaVector3.super.ctor(self,x,y,z)
    end

    function LuaVector3:__add(p2)
        local p1 = self
        local result = LuaVector3.new(p1.x+p2.x,p1.y+p2.y,p1.z+p2.z)
        return result
    end

    function LuaVector3:__tostring()
        return string.format("[%s,%s,%s]",self.x,self.y,self.z)
    end

    local function test_LuaVector3()
        local p1 = LuaVector3.new(1,1,1)
        local p2 = LuaVector3.new(2,2,2)
        local p3 = p1 + p2
        print(string.format("%s + %s = %s",p1,p2,p3))
        print(string.format("p1.x=%s,p1.y=%s,p1.z=%s",p1.x,p1.y,p1.z))

        local p4 = LuaVector3(1,1,1)
        print(LuaVector3)
        print(string.format("p4.x=%s,p4.y=%s,p4.z=%s",p4.x,p4.y,p4.z))
    end

    test_LuaVector3()

    --基类为function,表示继承自userdata,该function就是__ctor函数,他和提供__ctor函数是等价的
    local CSVector3 = class("CSVector3",function (self,x,y,z)
        local userdata = CS.UnityEngine.Vector3(x,y,z)
        -- 如果想通过userdata直接调用自身扩展的方法,则可通过setpeer设置peer表
        setpeer(userdata,self)
        return userdata
    end)

    local CSVector3 = class("CSVector3")

    function CSVector3:__ctor(x,y,z)
        local userdata = CS.UnityEngine.Vector3(x,y,z)
        -- 如果想通过userdata直接调用自身扩展的方法,则可通过setpeer设置peer表
        setpeer(userdata,self)
        return userdata
    end

    function CSVector3:ctor(x,y,z)
    end

    function CSVector3:__add(p2)
    local p1 = self
    local result = CSVector3.new(p1.x+p2.x,p1.y+p2.y,p1.z+p2.z)
    return result
    end

    function CSVector3:__tostring()
    return string.format("[%s,%s,%s]",self.x,self.y,self.z)
    end

    function CSVector3:test()
        print("CSVector3:test",type(self),self)
    end

    local function test_CSVector3()
        local p1 = CSVector3.new(1,1,1)
        local p2 = CSVector3.new(2,2,2)
        local p3 = p1 + p2
        print(string.format("%s + %s = %s",p1,p2,p3))
        print(string.format("p1.x=%s,p1.y=%s,p1.z=%s",p1.x,p1.y,p1.z))
        print(string.format("p1.x=%s,p1.y=%s,p1.z=%s",p1.__userdata.x,p1.__userdata.y,p1.__userdata.z))

        p1:test()
        p1.__userdata:test()
        p1.newvalue = 1
        print("lua#newvalue",p1.newvalue)
        print("userdata#newvalue",p1.__userdata.newvalue)
        p1.__userdata.newvalue = 2
        print("lua#newvalue",p1.newvalue)
        print("userdata#newvalue",p1.__userdata.newvalue)
    end
@endcode
]]

if not table.new then
    function table.new(narr,nrec)
        return {}
    end
end

local rawget = rawget
local rawset = rawset
local ipairs = ipairs
local pairs = pairs
local getmetatable = getmetatable
local setmetatable = setmetatable
local type = type
local assert = assert

local ggclass = _G

local function _reload_class(name)
    local class_type = assert(ggclass[name],name)
    -- 清空缓存的父类属性
    for k,v in pairs(class_type.__vtb) do
        class_type.__vtb[k] = nil
    end
    class_type.__vtb.__class = class_type
    --print(string.format("reload class,name=%s class_type=%s vtb=%s",name,class_type,vtb))
    return class_type
end

---@brief 分文件定义类
---@param name string 类名
---@return table 类
function partial_class(name)
    local class_type = ggclass[name]
    _reload_class(name)
    for name,_ in pairs(class_type.__children) do
        partial_class(name)
    end
    return class_type
end

local reload_class = partial_class

---@brief 定义类
---@param name string 类名
---@param ... any 若干基类
---@return table 类
function class(name,...)
    local supers = {...}
    local class_type = ggclass[name] or {}
    if not class_type.__children then
        class_type.__children = {}
    end
    if class_type.__supers then
        for _,super_class in ipairs(class_type.__supers) do
            if super_class.__children then
                super_class.__children[name] = nil
            end
        end
    end
    if type(supers[#supers]) == "function" then
        class_type.__ctor = table.remove(supers,#supers)
    end
    class_type.__supers = {}
    class_type.extend = function (class_type,super_class)
        assert(super_class ~= class_type)
        class_type.__supers[#class_type.__supers+1] = super_class
        if super_class.__children[name] then
            return class_type
        end
        if super_class.__extend then
            super_class:__extend(class_type)
        end
        super_class.__children[name] = true
        return class_type
    end

    for _,super_class in ipairs(supers) do
        class_type:extend(super_class)
    end
    if DEBUG_CLASS then
        local info = debug.getinfo(2,"S")
        local filename = info.source
        class_type.__filename = filename
    end
    class_type.__name = name
    class_type.super = supers[1]
    class_type.ctor = false
    class_type.__PROPERTY_COUNT = class_type.__PROPERTY_COUNT or 8
    if not ggclass[name] then
        ggclass[name] = class_type
        class_type.__new = function (...)
            local instance = table.new(0,class_type.__PROPERTY_COUNT)
            setmetatable(instance,class_type)
            local create = class_type.__ctor
            if create then
                -- __ctor函数返回值一般是个userdata
                instance.__userdata = create(instance,...)
                if class_type.__index == class_type.__vtb then
                    local vtb = class_type.__index
                    class_type.__index = function (instance,k)
                        local v = vtb[k]
                        if v ~= nil then
                            return v
                        end
                        return instance.__userdata[k]
                    end
                end
            end
            return instance
        end
        class_type.new = function (...)
            local instance = class_type.__new(...)
            if class_type.ctor then
                class_type.ctor(instance,...)
            end
            return instance
        end
        class_type.__vtb = {}
        class_type.__index = class_type.__vtb
        local vtb = class_type.__vtb
        setmetatable(class_type,{
            __index = class_type.__vtb,
            __call = function (class_type,...)
                return class_type.new(...)
            end,
            __newindex = function (class_type,k,v)
                rawset(class_type,k,v)
                class_type.__vtb[k] = v
            end
        })
        setmetatable(vtb,{__index = function (vtb,k)
            local result = rawget(class_type,k)
            if result == nil then
                for _,super_type in ipairs(class_type.__supers) do
                    result = super_type[k]
                    if result ~= nil then
                        break
                    end
                end
            end
            if result ~= nil then
                vtb[k] = result
            end
            return result
        end})
    end
    reload_class(name)
    return class_type
end

---@brief 判断类是否是另一个类的子类/子类的子类等
---@param cls1 table 子类
---@param cls2 table 父类
---@return bool true=是,false=否
function issubclass(cls1,cls2)
    local classname = cls1.__name
    if not classname then
        return false
    end
    if not cls2.__children then
        return false
    end
    if cls2.__children[classname] then
        return true
    end
    for subname,_ in pairs(cls2.__children) do
        if issubclass(cls1,ggclass[subname]) then
            return true
        end
    end
    return false
end

---@brief 获取实例类型名
---@param any 实例
---@return string 类型名(如果实例不是一个类对象,返回值同type函数返回,否则返回类名)
function typename(obj)
    local basetype = type(obj)
    if basetype == "userdata" then
        local meta = getmetatable(obj)
        if meta and meta.__name then
            return meta.__name
        end
    end
    if basetype ~= "table" then
        return basetype
    end
    local name = obj.__name
    if name then
        return name
    end
    return basetype
end

---@brief 判断对象是否为指定类的实例
---@param obj table 对象
---@param cls table 类对象
---@return bool true=是指定类实例,false=不是指定类实例
function isinstance(obj,cls)
    if not cls then
        return false
    end
    local classname = assert(cls.__name,"parameter 2 must be a class")
    if typename(obj) == classname then
        return true
    end
    for classname,_ in pairs(cls.__children) do
        if isinstance(obj,ggclass[classname]) then
            return true
        end
    end
    return false
end

---@brief 获取实例所属类
---@param instance table 实例
---@return table|nil nil=不是类创建的实例,其他=类对象
function classof(instance)
    local classname = instance.__name
    if not classname then
        return
    end
    return ggclass[classname]
end

__peers = __peers or setmetatable({},{__mode = "k"})

---@brief 获取userdata绑定的lua实例
---@param userdata 用户数据
---@return table lua实例对象,不存在返回nil
function getpeer(userdata)
    return __peers[userdata]
end

---@brief 设置userdata绑定的lua实例
---@param userdata 用户数据
---@param instance lua实例对象
function setpeer(userdata,instance)
    assert(__peers[userdata] == nil)
    __peers[userdata] = instance
    local meta = getmetatable(userdata)
    if not meta then
        meta = {}
        setmetatable(userdata,meta)
    end
    if rawget(meta,"__peer") then
        return
    end
    rawset(meta,"__peer",true)
    local index_old = meta.__index
    local newindex_old = meta.__newindex
    meta.__index_old = meta.__index
    meta.__newindex_old = meta.__newindex
    meta.__index = function (userdata,k)
        local v
        if index_old then
            if type(index_old) == "table" then
                v = index_old[k]
            else
                v = index_old(userdata,k)
            end
        end
        if v ~= nil then
            return v
        end
        local instance = getpeer(userdata)
        if instance == nil then
            -- 没有调用setpeer的userdata
            return nil
        end
        local cls = ggclass[instance.__name]
        local v = rawget(instance,k)
        if v == nil and cls then
            v = cls[k]
        end
        return v
    end
    meta.__newindex = function (userdata,k,v)
        local instance = getpeer(userdata)
        if instance and rawget(instance,k) ~= nil then
            rawset(instance,k,v)
            return
        end
        if newindex_old then
            if type(newindex_old) == "table" then
                newindex_old[k] = v
            else
                newindex_old(userdata,k,v)
            end
        end
    end
end
