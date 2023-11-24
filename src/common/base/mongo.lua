--[[! 示例
@code
    loal db = Mongo.getMongo()
    local data = db:loadFromDB("player",{pid=1000000})
    db:saveToDB("player",{pid=1000000},data)
@endcode
]]
local skynet = require "skynet"
require "skynet.manager"
local mongo = require "skynet.db.mongo"

local Mongo = class("Mongo")
Mongo.instances = Mongo.instances or {}

---@brief 获取mongo单例对象,实例名为本服服务器id
---@return MongoInstance mongo客户端实例
function Mongo.getMongo()
    local instance = Mongo.instance
    if not instance then
        local config = require "config.custom"
        instance = Mongo.createInstance(config.mongodb_config, skynet.getenv("id"))
        Mongo.instance = instance
    end
    return instance
end

function Mongo.getdb()
    local db = Mongo.getMongo()
    return db.db
end

---@brief 获取一个mongo实例
---@param instanceId int/string 实例id
---@return MongoInstance mongo客户端实例
function Mongo.getInstance(instanceId)
    return Mongo.instances[instanceId]
end

---@brief 创建一个mongo实例
---@param config table mongodb连接配置
---@param instanceId int/string 实例id,不同实例间需要保持唯一
---@return MongoInstance mongo客户端实例
function Mongo.createInstance(config,instanceId)
    local instance = Mongo.new(config,instanceId)
    Mongo.instances[instanceId] = instance
    instance:connect()
    return instance
end

---@brief 销毁一个mongo实例
---@param instanceId int/string 实例id
function Mongo.destroyInstance(instanceId)
    local instance = Mongo.getInstance(instanceId)
    if not instance then
        return
    end
    instance:disconnect()
end

---@brief 关闭所有mongo实例
function Mongo.stop()
    for instanceId in pairs(Mongo.instances) do
        Mongo.destroyInstance(instanceId)
    end
end

function Mongo:ctor(config,instanceId)
    self.config = config
    self.isCluster = self.config.is_cluster
    self.id = assert(instanceId)                -- 实例id
    self.client = nil                           -- 连接实例
    self.db = nil                               -- 选择的db库
end

function Mongo:connect()
    local client = mongo.client(
        self.config.rs[1]
	)
    assert(client)
    self.client = client
    self.db = self.client[self.config.db]
    return client
end

function Mongo:connectOnce()
    return mongo.client(self.config)
end

function Mongo:disconnect()
    local client = self.client
    if not client then
        return
    end
    self.client = nil
    self.db = nil
    if Mongo.instance == self then
        Mongo.instance = nil
    end
    Mongo.instances[self.id] = nil
    client:disconnect()
end

---@brief 从表中载入1条记录
---@param tblName string 表名
---@param query table 查询条件
---@param projection table [optional] 查询哪些字段,默认查询所有
---@return table 一条记录数据
function Mongo:loadFromDB(tblName,query,projection)
    local data = self.db[tblName]:findOne(query,projection)
    if data then
        data._id = nil
    end
    return data
end

---@brief 将一条记录保存到db表,上层不等待保存结果
---@param tblName string 表名
---@param query table 查询条件
---@param update table 记录数据
function Mongo:saveToDB(tblName,query,update)
    local upsert = true
    local multi = false
    self.db[tblName]:update(query,update,upsert,multi)
end

---@brief 将一条记录保存到db表,上层等待保存完毕才返回
---@param tblName string 表名
---@param query table 查询条件
---@param update table 记录数据
---@return bool true=保存成功
---@return string 失败消息
function Mongo:safeSaveToDB(tblName,query,update)
    local upsert = true
    local multi = false
    local ok,err,result = self.db[tblName]:safe_update(query,update,upsert,multi)
    if not ok then
        logger.info("save","op=saveToDB,tblName=%s,query=%s,update=%s,upsert=%s,multi=%s,err=%s",tblName,query,update,upsert,multi,err)
    end
    return ok,err,result
end

---@brief 从表中删除一条记录,上层不等待删除结果
---@param tblName string 表名
---@param query table 查询条件
function Mongo:deleteFromDB(tblName,query,multi)
    local single = not multi
    self.db[tblName]:delete(query,single)
end

---@brief 从表中删除一条记录,上层等待删除完毕才返回
---@param tblName string 表名
---@param query table 查询条件
---@return bool true=保存成功
---@return string 失败消息
function Mongo:safeDeleteFromDB(tblName,query,multi)
    local single = not multi
    return self.db[tblName]:safe_delete(query,single)
end

---@brief 从表中删除所有记录
---@param tblName string 表名
function Mongo:deleteAllFromDB(tblName)
    self.db[tblName]:delete({})
end

---@brief 从表中删除所有记录,上层等待删除完毕才返回
---@param tblName string 表名
function Mongo:safeDeleteAllFromDB(tblName)
    return self.db[tblName]:safe_delete({})
end

---@brief 删除表
---@param tblName string 表名
function Mongo:dropTable(tblName)
    return self.db[tblName]:drop()
end

---@brief 批量插入,上层不等待插入结果
---@param tblName string 表名
---@param records list 记录列表
function Mongo:batchInsert(tblName,records)
    self.db[tblName]:batch_insert(records)
end

---@brief 批量插入,上层等待插入完毕后才返回
---@param tblName string 表名
---@param records list 记录列表
function Mongo:safeBatchInsert(tblName,records)
    return self.db[tblName]:safe_batch_insert(records)
end

---@brief 批量更新,上层不等待更新结果
---@param tblName string 表名
---@param records list 记录列表
function Mongo:batchUpdate(tblName,records)
    self.db[tblName]:batch_update(records)
end

---@brief 批量更新,上层等待更新完毕后才返回
---@param tblName string 表名
---@param records list 记录列表
function Mongo:safeBatchUpdate(tblName,records)
    return self.db[tblName]:safe_batch_update(records)
end

---@brief 创建索引
---@param tblName string 表名
---@param indexes list 索引列表
function Mongo:createIndexes(tblName,indexes)
    return self.db[tblName]:createIndexes(indexes)
end

return Mongo
