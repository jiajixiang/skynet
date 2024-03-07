-- $Id$
-- __auto_local__start--
local string = string
local table = table
local math = math
local pairs = pairs
local tonumber = tonumber
-- __auto_local__end--

--------------------------- 基本接口

local offSecForTest = 0

function addTestHour(hour)
    offSecForTest = offSecForTest + hour * 3600
end

function addTestMin(min)
    offSecForTest = offSecForTest + min * 60
end

function addTestSec(sec)
    offSecForTest = offSecForTest + sec
end

function resetTestTime()
    offSecForTest = 0
end

function setTestTime(year, mon, day, hour, min, sec)
    local curTime = os.time()
    local needTime = osBJSecByTbl({
        year = year,
        month = mon,
        day = day,
        hour = hour,
        min = min,
        sec = sec
    })
    offSecForTest = needTime - curTime
end

function osBJSec()
    return os.time() + offSecForTest
end

function osBJDate()
    local cur_secs = osBJSec()
    return os.date("*t", cur_secs)
end

function osBJDateBySec(sec)
    return os.date("*t", sec)
end

function osBJDateFmtBySec(sec)
    return os.date("%Y-%m-%d %H:%M:%S", sec)
end

function osBJDateSubTime(sec)
    local cur_secs = osBJSec()
    cur_secs = cur_secs - sec
    return os.date("*t", cur_secs)
end

function osBJSecByTbl(tbl)
    local ret = os.time(tbl)
    return ret
end

local TIME_BASE = osBJSecByTbl({
    year = 2004,
    month = 1,
    day = 1,
    hour = 0,
    min = 0,
    sec = 0
})

-- to client
function conv2_client_time(beijing_time)
    return beijing_time
end

function os_client_time()
    return osBJSec()
end

-----------------------------------
-- 返回所给时间是相对于2004年1月1日为第一天开始算起的的第几天
function GetRelaDayNo(Time)
    local TotalDay = 0
    local Standard = TIME_BASE
    if not Time then
        Time = osBJSec()
    end
    assert(Time > Standard)
    TotalDay = (Time - Standard) / 3600 / 24
    return math.floor(TotalDay) + 1
end

-- 返回所给时间是相对于2004年1月1日5时0分0秒为第一天开始算起的的第几天
function GetDefaultUpRelaDayNo(Time)
    local TotalDay = 0
    local Standard = TIME_BASE + 5 * 3600
    if not Time then
        Time = osBJSec()
    end
    assert(Time > Standard)
    TotalDay = (Time - Standard) / 3600 / 24
    return math.floor(TotalDay) + 1
end

-- 返回所给时间是相对于2004年1月1日某时为第一天开始算起的的第几天
function GetCustomRelaDayNo(Time, hour)
    local TotalDay = 0
    local Standard = TIME_BASE + hour * 3600
    if not Time then
        Time = osBJSec()
    end
    assert(Time > Standard)
    TotalDay = (Time - Standard) / 3600 / 24
    return math.floor(TotalDay) + 1
end

function calNextMonthSec() -- 返回当前到下一个月的1号0点还需多少秒
    local CurTime = osBJDate()
    local Year = CurTime.year
    local Month = CurTime.month

    local EndTime = nil
    if Month + 1 == 13 then
        EndTime = {
            year = Year + 1,
            month = 1,
            day = 1,
            hour = 0,
            min = 0,
            sec = 0
        }
    else
        EndTime = {
            year = Year,
            month = Month + 1,
            day = 1,
            hour = 0,
            min = 0,
            sec = 0
        }
    end

    local StartSecs = osBJSec()
    local EndSecs = osBJSecByTbl(EndTime)

    local SubSecs = EndSecs - StartSecs
    assert(SubSecs > 0)
    return SubSecs
end

function GetDayNumOfMonth(Year, Month) -- 返回Year Month有多少天
    local CurTime = osBJDate()
    Year = Year or CurTime.year
    Month = Month or CurTime.month

    local StartTime = {
        year = Year,
        month = Month,
        day = 1,
        hour = 0,
        min = 0,
        sec = 0
    }

    local EndTime = nil
    if Month + 1 == 13 then
        EndTime = {
            year = Year + 1,
            month = 1,
            day = 1,
            hour = 0,
            min = 0,
            sec = 0
        }
    else
        EndTime = {
            year = Year,
            month = Month + 1,
            day = 1,
            hour = 0,
            min = 0,
            sec = 0
        }
    end

    local StartSecs = osBJSecByTbl(StartTime)
    local EndSecs = osBJSecByTbl(EndTime)

    local SubSecs = EndSecs - StartSecs
    assert(SubSecs > 0)
    return math.floor((SubSecs / 86400)) -- 理论上不会有小数
end

function GetRelaTimeNo(hour, min, sec) -- 当前是第几个hour min sec
    local offStandard = TIME_BASE + hour * 3600 + min * 60 + sec
    local cur_time = osBJSec()
    local TotalDay = (cur_time - offStandard) / 3600 / 24
    return math.floor(TotalDay) + 1
end

function GetDefaultUpRelaTimeNo()
    return GetRelaTimeNo(COMMON_CONST.UPDATE_HOUR, 0, 0)
end

function GetDayBeiJingTime(daySec, hour, min, sec)
    local t = osBJDateBySec(daySec)
    t.hour = hour
    t.min = min
    t.sec = sec
    return osBJSecByTbl(t)
end

-- 当天的某个时间点
function GetCurDayBeiJingTime(hour, min, sec)
    local t = osBJDate()
    t.hour = hour
    t.min = min
    t.sec = sec
    return osBJSecByTbl(t)
end

---得到几天后默认更新的秒数
function GetSomeDayDefaultRelaSec(days)
    local sec = GetCurDayBeiJingTime(COMMON_CONST.UPDATE_HOUR, 0, 0) + days * 24 * 3600
    local date = osBJDate()
    if date.hour >= 0 and date.hour < 5 then
        sec = sec - 24 * 3600
    end
    return sec
end

function getDeltaSecToTimeAccordingDate(date, hour, min, sec)
    local dst_day_sec = hour * 3600 + min * 60 + sec
    local cur_day_sec = date.hour * 3600 + date.min * 60 + date.sec
    if cur_day_sec >= dst_day_sec then
        dst_day_sec = dst_day_sec + 3600 * 24
    end

    return (dst_day_sec - cur_day_sec)
end

function getDeltaSecToTime(hour, min, sec) -- 获取到下一个hour min sec还要多少秒
    local date = osBJDate()
    return getDeltaSecToTimeAccordingDate(date, hour, min, sec)
end

function secToGetHMS(sec)
    local hour = math.floor(sec / 3600)
    sec = sec - hour * 3600
    local min = math.floor(sec / 60)
    sec = sec - min * 60
    return hour, min, sec
end

function secCeilGetHM(sec)
    sec = sec + 60
    local hour = math.floor(sec / 3600)
    sec = sec - hour * 3600
    local min = math.floor(sec / 60)
    return hour, min
end

function secToHMS(sec)
    return string.format("%.2d:%.2d:%.2d", secToGetHMS(sec))
end

local wdayToCN = {
    [1] = 7,
    [2] = 1,
    [3] = 2,
    [4] = 3,
    [5] = 4,
    [6] = 5,
    [7] = 6
}

function getCNWDay()
    local date = osBJDate()
    return wdayToCN[date.wday]
end

function calDaySecNextWdaySec(daySec, wday) -- 返回某个时间到下个wday的O点还需多少秒
    local date = osBJDateBySec(daySec)
    local addDay = (7 - date.wday + wday - 1) % 7
    local addSec = getDeltaSecToTimeAccordingDate(date, 0, 0, 0)
    local allSec = addSec + addDay * 24 * 3600
    return allSec
end

function calNextWdaySec(wday) -- 返回当前到下一个wday的0点还需多少秒
    local date = osBJDate()
    local addDay = (7 - date.wday + wday - 1) % 7
    local addSec = getDeltaSecToTime(0, 0, 0)
    local allSec = addSec + addDay * 24 * 3600
    return allSec
end

function getNextWdaySec(wday)
    local date = osBJDate()
    date.hour = 5
    date.sec = 0
    date.min = 0
    local curSec = osBJSecByTbl(date)
    local addDay = (7 + wday - date.wday) % 7
    local retSec = curSec + addDay * 24 * 3600
    if osBJSec() > retSec then
        retSec = retSec + 7 * 24 * 3600
    end
    return retSec
end

function GetRelaWeekNo(Time)
    local TotalWeek = 0
    local Standard = TIME_BASE + 3600 * 24 * 4 -- 因为2004年1月1日 0:00是星期四早上0:00，要改成星期日24:00
    Time = Time or osBJSec()
    if Time > Standard then
        TotalWeek = (Time - Standard) / 3600 / 24 / 7
    else
        TotalWeek = (Standard - Time) / 3600 / 24 / 7
    end
    return math.floor(TotalWeek + 1)
end

function getNextTimeByConf(timeConf)
    --[[
	timeConf = {
		[1] = hour1,
		[2] = hour2,
	}
	--]]
    local curTime = osBJSec()
    for i, hour in ipairs(timeConf) do
        local refreshTime = GetCurDayBeiJingTime(hour, 0, 0)
        if curTime < refreshTime then
            return refreshTime
        end
    end
    local tomorrowUpTime = GetCurDayBeiJingTime(timeConf[1], 0, 0) + 3600 * 24
    return tomorrowUpTime
end
