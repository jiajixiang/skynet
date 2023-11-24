---@ingroup gg
---@brief 时间函数
---@author sundream
---@date 2019/3/29
---@package Time

Time = Time or {}

if skynet then
    Time.appTimeZone = tonumber(skynet.getenv("timeZone"))
    Time.dateFormat = skynet.getenv("dateFormat")
end

Time.HOUR_SECS = 3600
Time.DAY_SECS = 24 * Time.HOUR_SECS
Time.WEEK_SECS = 7 * Time.DAY_SECS

---@brief 获取本地(机器所在时区)时间戳
---@param tbl table [optional] 代表时间的table表示,用法同os.time
---@return int 时间戳(秒)
function Time.localtime(tbl)
    return os.time(tbl)
end

---@brief 获取本地时区(机器所在的时区)
---@return int 时区偏移值
--[[! 示例
@code
    Time.zone() => 8
@endcode
]]
function Time.zone()
    if Time._zone then
        return Time._zone
    end
    local t = os.time()
    local diff = os.difftime(t, os.time(os.date("!*t", t)))
    diff = math.tointeger(diff)

    local zone = math.floor(diff / Time.HOUR_SECS)
    Time._zone = zone
    return zone
end

Time.dateFormat = Time.dateFormat or "%Y-%m-%d %H:%M:%S"
Time.appTimeZone = Time.appTimeZone or Time.zone()


---@brief 获取玩家所在时区当前时间戳(秒为单位)
---@param [optional] table 表示日期的table,用法同os.time
---@return int 秒数
function Time.time(tbl)
    local zoneTime = (Time.appTimeZone - Time.zone()) * Time.HOUR_SECS
    return Time.localtime(tbl) + zoneTime
end

---@brief 获取当前毫秒时间
---@return int 毫秒时间
function Time.getms()
    local lutil = require "lutil"
    local zoneTime = (Time.appTimeZone - Time.zone()) * Time.HOUR_SECS
    return lutil.getms() + zoneTime * 1000
end

---@brief 纪元0(标准纪元): 1970-01-01 00:00:00 周四 1月1日
Time.STARTTIME0 = Time.time({year=1970,month=1,day=1,hour=0,min=0,sec=0})
---@brief 纪元1: 2014-08-25 00:00:00 周一 8月25日
Time.STARTTIME1 = Time.time({year=2014,month=8,day=25,hour=0,min=0,sec=0})
---@brief 纪元2: 2014-08-24 00:00:00 周日 8月24日
Time.STARTTIME2 = Time.time({year=2014,month=8,day=24,hour=0,min=0,sec=0})

---@brief 获取世界标准时间当前时间戳(秒为单位)
---@param tbl table [optional] 表示日期的table,用法同os.time
---@return int 秒数
function Time.utctime(tbl)
    local now = Time.time(tbl)
    return Time.toUtcTime(now)
end

---将当前时间戳转为UTC标准时间戳
function Time.toUtcTime(now)
    now = now or Time.time()
    return now - Time.appTimeZone * Time.HOUR_SECS
end

---@brief 获取从自定义纪元开始经过的分钟个数
---@param now int [optional] 待计算的时间,默认为当前时间
---@param starttime int [optional] 纪元时间点,默认为纪元1
---@return int 经过的分钟数
function Time.minuteno(now,starttime)
    now = now or Time.time()
    starttime = starttime or Time.STARTTIME1
    local diff = now - starttime
    return math.floor(diff/60) + 1
end


---@brief 获取从自定义纪元开始经过的5分钟个数
---@param now int [optional] 待计算的时间,默认为当前时间
---@param starttime int [optional] 纪元时间点,默认为纪元1
---@return int 经过的五分钟数
function Time.fiveminuteno(now,starttime)
    now = now or Time.time()
    starttime = starttime or Time.STARTTIME1
    local diff = now - starttime
    return math.floor(diff/300) + 1
end

---@brief 获取从自定义纪元开始经过的半小时数
---@param now int [optional] 待计算的时间,默认为当前时间
---@param starttime int [optional] 纪元时间点,默认为纪元1
---@return int 经过的半小时数
function Time.halfhourno(now,starttime)
    now = now or Time.time()
    starttime = starttime or Time.STARTTIME1
    local diff = now - starttime
    return math.floor(2*diff/Time.HOUR_SECS) + 1
end

---@brief 获取从自定义纪元开始经过的小时数
---@param now int [optional] 待计算的时间,默认为当前时间
---@param starttime int [optional] 纪元时间点,默认为纪元1
---@return int 经过的小时数
function Time.hourno(now,starttime)
    now = now or Time.time()
    starttime = starttime or Time.STARTTIME1
    local diff = now - starttime
    return math.floor(diff/Time.HOUR_SECS) + 1
end

---@brief 获取从自定义纪元开始经过的天数
---@param now int [optional] 待计算的时间,默认为当前时间
---@param starttime int [optional] 纪元时间点,默认为纪元1
---@return int 经过的天数
function Time.dayno(now,starttime)
    now = now or Time.time()
    starttime = starttime or Time.STARTTIME1
    local diff = now - starttime
    return math.floor(diff/Time.DAY_SECS) + 1
end

---@brief 获取从自定义纪元开始经过的礼拜数
---@param now int [optional] 待计算的时间,默认为当前时间
---@param starttime int [optional] 纪元时间点,默认为纪元1
---@return int 经过的礼拜数
function Time.weekno(now,starttime)
    now = now or Time.time()
    starttime = starttime or Time.STARTTIME1
    local diff = now - starttime
    return math.floor(diff/Time.WEEK_SECS) + 1
end

---@brief 获取从自定义纪元开始经过的月数
---@param now int [optional] 待计算的时间,默认为当前时间
---@param starttime int [optional] 纪元时间点,默认为纪元1
---@return int 经过的月数
function Time.monthno(now,starttime)
    now = now or Time.time()
    starttime = starttime or Time.STARTTIME1
    local year1 = Time.year(starttime)
    local month1 = Time.month(starttime)
    local year2 = Time.year(now)
    local month2 = Time.month(now)
    return (year2 - year1) * 12 + month2 - month1
end

---@brief 获取当前为第几年
---@param now int [optional] 待计算的时间,默认为当前时间
---@return int 第几年
function Time.year(now)
    now = now or Time.time()
    local s = os.date("%Y",now)
    return tonumber(s)
end

---@brief 获取当前为本年第几月
---@param now int [optional] 待计算的时间,默认为当前时间
---@return int 第几月[1,12]
function Time.month(now)
    now = now or Time.time()
    local s = os.date("%m",now)
    return tonumber(s)
end

---@brief 获取当前为本月第几天
---@param now int [optional] 待计算的时间,默认为当前时间
---@return int 第几天[1,31]
function Time.day(now)
    now = now or Time.time()
    local s = os.date("%d",now)
    return tonumber(s)
end

---@brief 本月有多少天
---@param month int [optional] 本年的月份,不指定则为本月
---@return int 多少天
function Time.howmuchdays(month)
    month = month or Time.month()
    local month_zerotime = Time.time({year=Time.year(),month=month,day=1,hour=0,min=0,sec=0})
    for _,monthday in ipairs({31,30,29,28}) do
        local timestamp = month_zerotime + monthday * Time.DAY_SECS - 1
        if Time.month(timestamp) == month then
            return monthday
        end
    end
    assert("Invalid month:" .. tostring(month))
end

---@brief 今年过去的天数
---@param now int [optional] 待计算的时间,默认为当前时间
---@return int 天数[1,366]
function Time.yearday(now)
    now = now or Time.time()
    local s = os.date("%j",now)
    return tonumber(s)
end

---@brief 今天为星期几(星期天为0)
---@param now int [optional] 待计算的时间,默认为当前时间
---@return int 星期几[0,6]
function Time.weekday(now)
    now = now or Time.time()
    local s = os.date("%w",now)
    return tonumber(s)
end

---@brief 获取当前小时
---@param now int [optional] 待计算的时间,默认为当前时间
---@return int 小时[0,23]
function Time.hour(now)
    now = now or Time.time()
    local s = os.date("%H",now)
    return tonumber(s)
end

---@brief 获取当前分钟
---@param now int [optional] 待计算的时间,默认为当前时间
---@return int 分钟[0,59]
function Time.minute(now)
    now = now or Time.time()
    local s = os.date("%M",now)
    return tonumber(s)
end

---@brief 获取当前秒
---@param now int [optional] 待计算的时间,默认为当前时间
---@return int 秒[0,59]
function Time.second(now)
    now = now or Time.time()
    local s = os.date("%S",now)
    return tonumber(s)
end

---@brief 获取当天过去的秒数
---@param now int [optional] 待计算的时间,默认为当前时间
---@return int 秒数
function Time.daysecond(now)
    now = now or Time.time()
    return Time.hour(now) * Time.HOUR_SECS + Time.minute(now) * 60 + Time.second(now)
end

---@brief 获取当天0点时间(秒为单位)
---@param now int [optional] 待计算的时间,默认为当前时间
---@return int 当天0点时间(秒为单位)
function Time.dayzerotime(now)
    now = now or Time.time()
    return now - Time.daysecond(now)
end

---@brief 获取当周0点
---@param now int [optional] 待计算的时间,默认为当前时间
---@param week_start_day int [optional] 周起点天数,默认为周一,如果为周天为起点,则填0
---@return int 当周0点时间
function Time.weekzerotime(now,week_start_day)
    now = now or Time.time()
    week_start_day = week_start_day or 1
    local weekday = Time.weekday(now)
    weekday = weekday == 0 and 7 or weekday
    local diffday = weekday - week_start_day
    return Time.dayzerotime(now-diffday*Time.DAY_SECS)
end

---@brief 获取当月0点
---@param now int [optional] 待计算的时间,默认为当前时间
---@return int 当月0点
function Time.monthzerotime(now)
    now = now or Time.time()
    local monthday = Time.day(now)
    return Time.dayzerotime(now-monthday*Time.DAY_SECS)
end

---@brief 下个月0点
---@param now int [optional] 待计算的时间,默认为当前时间
---@return int 当月0点
function Time.nextmonthzerotime(now)
    now = now or Time.time()
    return Time.time({year=Time.year(now),month=Time.month(now)+1,day=1,hour=0,min=0,sec=0,})
end

---@brief 将秒数格式化为{day=天,hour=小时,min=分钟,sec=秒}的表示
---@param fmt table 格式表,形如{day=true,hour=true,min=true,sec=true}
---@param secs int 秒数
---@return table 格式化后的时间表
--[[! 示例
@code
    local secs = 3661
    local t = Time.dhms({hour=true})
    got {day=0,hour=1,min=0,sec=61},格式只指定了hour,因此只有hour是精确的
    local t = Time.dhms({hour=true,min=true,sec=true})
    got {day=0,hour=1,min=1,sec=1},格式只指定了hour,min,sec,因此hour,min,sec都精确
@endcode
]]
function Time.dhms(fmt,secs)
    if secs < 0 then
        secs = 0
    end
    local day = math.floor(secs/Time.DAY_SECS)
    local hour = math.floor(secs/Time.HOUR_SECS)
    local min = math.floor(secs/60)
    local sec = secs
    if fmt.day then
        hour = hour - 24 * day
        min = min - 24*60 * day
        sec = sec - 24*3600 * day
    end
    if fmt.hour then
        min = min - 60 * hour
        sec = sec - 3600 * hour
    end
    if fmt.min then
        sec = sec - 60 * min
    end
    return {
        day = day,
        hour = hour,
        min = min,
        sec = sec,
    }
end


---@brief 格式化秒数，最大粒度：天
---@param fmt string 格式字符串
---@param secs int 秒数
---@return string 格式化后的时间字符串
---@details
---* fmt构成元素:
---* %D : XX day
---* %H : XX hour
---* %M : XX minute
---* %S : XX sec
---* %d/%h/%m/%s含义同对应大写格式,但是不会0对齐
--[[! 示例
@code
    Time.strftime("%D天%H时%S秒",30*24*3600+3601) => 30天01时01秒
    Time.strftime("%h时%s秒",30*24*3600+3601) => 721时1秒
    -- 假定翻译文本为: %D天%H时%S秒<:>%D day %H hour %S second
    Time.strftime(i18n.format(10000),30*24*3600+3601) => 30 day 01 hour 01 second
@endcode
]]
function Time.strftime(fmt,secs)
    local startpos = 1
    local endpos = string.len(fmt)
    local has_fmt = {}
    local pos = startpos
    while pos <= endpos do
        local findit,fmtflag
        findit,pos,fmtflag = string.find(fmt,"%%([dhmsDHMS])",pos)
        if not findit then
            break
        else
            pos = pos + 1
            has_fmt[fmtflag] = true
        end
    end
    if not next(has_fmt) then
        return fmt
    end
    local date_fmt = {sec=true}
    if has_fmt["d"] or has_fmt["D"] then
        date_fmt.day = true
    end
    if has_fmt["h"] or has_fmt["H"] then
        date_fmt.hour = true
    end
    if has_fmt["m"] or has_fmt["M"] then
        date_fmt.min = true
    end
    local date = Time.dhms(date_fmt,secs)
    local DAY = string.format("%02d",date.day)
    local HOUR = string.format("%02d",date.hour)
    local MIN = string.format("%02d",date.min)
    local SEC = string.format("%02d",date.sec)
    local day = tostring(date.day)
    local hour = tostring(date.hour)
    local min = tostring(date.min)
    local sec = tostring(date.sec)
    local repls = {
        d = day,
        h = hour,
        m = min,
        s = sec,
        D = DAY,
        H = HOUR,
        M = MIN,
        S = SEC,
    }
    return string.gsub(fmt,"%%([dhmsDHMS])",repls)
end

---@brief 获取整点时间戳
---@param hour int 整点小时[0,23]
---@param now int [optional] 待计算的时间,默认为当前时间
---@return int 整点时间戳（秒）
function Time.hourtime(hour, now)
    assert(hour>=0 and hour<=23)
    local zero = Time.dayzerotime(now)
    return zero + hour * Time.HOUR_SECS
end

---@brief 格式化日期
---@param now int [optional] 当前时间戳
---@param fmt string [optional] 日期格式,默认为skynet.config.dateFormat
---@return string 格式化后的时间字符串
--[[! 示例
@code
    Time.date() => 2022-04-19 12:23:35
    Time.date("%Y年%m月%d日 %H时%M分%S秒",1678289145) => 2023年03月08日 23时25分45秒
    -- 假定翻译文本为: %Y年%m月%d日 %H时%M分%S秒<:>%Y-%m-%d %H:%M:%S
    Time.date(i18n.format(10001),1678289145) => 2023-03-08 23:25:45
@endcode
]]
function Time.date(fmt,now)
    fmt = fmt or Time.dateFormat
    now = now or Time.time()
    return os.date(fmt,now)
end

---@brief 获取时区名
---@return string 时区
--[[! 示例
@code
    Time.zonename() => UTC+8
@endcode
]]
function Time.zonename()
    local zone = Time.zone()
    return "UTC" .. (zone>=0 and "+"..zone or zone)
end

---@brief 将时间转换为秒数
---@return int 秒数
--[[! 示例
@code
    Time.timeToseconds("12:30:00") => 45000
@endcode
]]
function Time.timeToseconds(str)
    local hour, min, sec = string.match(str, "(%d+):(%d+):(%d+)")
    assert(hour and min and sec)
    hour = tonumber(hour)
    min = tonumber(min)
    sec = tonumber(sec)
    assert(hour >=0 and hour < 24, hour)
    assert(min >=0 and min < 60, min)
    assert(sec >=0 and sec < 60, sec)
    return hour * 3600 + min * 60 + sec
end

return Time
