local skynet = require "skynet"
require "skynet.manager"
local mongo = require "skynet.db.mongo"

allInstancesTbl = {}

local saveFieldTbl = {
    _col = function()
        return nil
    end
}

function getInstances(col)
    return allInstancesTbl[col]
end

clsMongo = clsObject:Inherit()

function clsMongo:__init__(oci)
    Super(clsMongo).__init__(self, oci)
    for k, func in pairs(saveFieldTbl) do
        if oci[k] == nil then
            self[k] = func()
        else
            self[k] = oci[k]
        end
    end
    allInstancesTbl[self._col] = self
    local config = require "config.custom"
    self.config = config["mongodb_config"]
    self.id = skynet.getenv("id")
    self.client = nil -- 连接实例
    self.db = nil -- 选择的db库
end

function clsMongo:connect()
    local client = mongo.client(self.config.rs[1])
    assert(client)
    self.client = client
    self.db = self.client[self.config.db]
    return client
end

function clsMongo:connectOnce()
    return mongo.client(self.config)
end

function clsMongo:disconnect()
    local client = self.client
    if not client then
        return
    end
    self.client = nil
    self.db = nil
    client:disconnect()
end

---@brief 从表中载入1条记录
---@param tblName string 表名
---@param query table 查询条件
---@param projection table [optional] 查询哪些字段,默认查询所有
---@return table 一条记录数据
function clsMongo:loadFromDB(tblName, query, projection)
    local data = self.db[tblName]:findOne(query, projection)
    if data then
        data._id = nil
    end
    return data
end

---@brief 将一条记录保存到db表,上层不等待保存结果
---@param tblName string 表名
---@param query table 查询条件
---@param update table 记录数据
function clsMongo:saveToDB(tblName, query, update)
    local upsert = true
    local multi = false
    self.db[tblName]:update(query, update, upsert, multi)
end

---@brief 将一条记录保存到db表,上层等待保存完毕才返回
---@param tblName string 表名
---@param query table 查询条件
---@param update table 记录数据
---@return bool true=保存成功
---@return string 失败消息
function clsMongo:safeSaveToDB(tblName, query, update)
    local upsert = true
    local multi = false
    local ok, err, result = self.db[tblName]:safe_update(query, update, upsert, multi)
    if not ok then
        logger.info("save", "op=saveToDB,tblName=%s,query=%s,update=%s,upsert=%s,multi=%s,err=%s", tblName, query,
            update, upsert, multi, err)
    end
    return ok, err, result
end

---@brief 从表中删除一条记录,上层不等待删除结果
---@param tblName string 表名
---@param query table 查询条件
function clsMongo:deleteFromDB(tblName, query, multi)
    local single = not multi
    self.db[tblName]:delete(query, single)
end

---@brief 从表中删除一条记录,上层等待删除完毕才返回
---@param tblName string 表名
---@param query table 查询条件
---@return bool true=保存成功
---@return string 失败消息
function clsMongo:safeDeleteFromDB(tblName, query, multi)
    local single = not multi
    return self.db[tblName]:safe_delete(query, single)
end

---@brief 从表中删除所有记录
---@param tblName string 表名
function clsMongo:deleteAllFromDB(tblName)
    self.db[tblName]:delete({})
end

---@brief 从表中删除所有记录,上层等待删除完毕才返回
---@param tblName string 表名
function clsMongo:safeDeleteAllFromDB(tblName)
    return self.db[tblName]:safe_delete({})
end

---@brief 删除表
---@param tblName string 表名
function clsMongo:dropTable(tblName)
    return self.db[tblName]:drop()
end

---@brief 批量插入,上层不等待插入结果
---@param tblName string 表名
---@param records list 记录列表
function clsMongo:batchInsert(tblName, records)
    self.db[tblName]:batch_insert(records)
end

---@brief 批量插入,上层等待插入完毕后才返回
---@param tblName string 表名
---@param records list 记录列表
function clsMongo:safeBatchInsert(tblName, records)
    return self.db[tblName]:safe_batch_insert(records)
end

---@brief 批量更新,上层不等待更新结果
---@param tblName string 表名
---@param records list 记录列表
function clsMongo:batchUpdate(tblName, records)
    self.db[tblName]:batch_update(records)
end

---@brief 批量更新,上层等待更新完毕后才返回
---@param tblName string 表名
---@param records list 记录列表
function clsMongo:safeBatchUpdate(tblName, records)
    return self.db[tblName]:safe_batch_update(records)
end

---@brief 创建索引
---@param tblName string 表名
---@param indexes list 索引列表
function clsMongo:createIndexes(tblName, indexes)
    return self.db[tblName]:createIndexes(indexes)
end

function getDb(col)
    local dbObj = getInstances(col)
    if not dbObj then
        local oci = {
            _col = col
        }
        dbObj = clsMongo:New(oci)
        dbObj:connect()
    end
    return dbObj.db
end

function __init__(...)
    -- body
end
