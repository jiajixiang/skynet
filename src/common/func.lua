
posResolution = 100

--timeStep = 0.1 
timeStep = 0.25 
battleStep = 0.25
roundFrameCnt = 8
delayFrameCnt = 6
imdDelayFrameCnt = 0

-- entity是位于整个tile范围偏左下一个坐标 因为tile范围是一偶数 所以entity是不会处于一个tile的中心点的 只有范围 没有中心点 中心点只是用来提供还原范围的

gridWidth = 1 * posResolution -- 1 client pos width
gridHeight = 1 * posResolution -- 1 client pos height 

xmaxTileCnt = 3648
zmaxTileCnt = 3648

areaCnt = 9

function convertToSrvDis(clientDis)
	return clientDis * posResolution
end

function convertToClientDis(srvDis)
	return srvDis / posResolution
end

function convertToSrvPos(x, z)
	return math.floor(x * posResolution), math.floor(z * posResolution)
end

local tileWidth = 1500 
local chunkToTile = 9

chunkWidth = chunkToTile*tileWidth
chunkHeight = chunkToTile*tileWidth 
maxChunkXCnt = math.ceil(xmaxTileCnt / chunkToTile)
maxChunkZCnt = math.ceil(zmaxTileCnt / chunkToTile)

function rangeChunk(cx, cz)
	if cx < 0 then
		cx = 0
	end
	if cx >= maxChunkXCnt then
		cx = maxChunkXCnt - 1
	end
	if cz < 0 then
		cz = 0
	end
	if cz >= maxChunkZCnt then
		cz = maxChunkZCnt - 1
	end
	return cx, cz
end

function convertSrvToChunk(srvx, srvz)
	return math.floor(srvx / chunkWidth), math.floor(srvz / chunkHeight)
end

function getPtoListValueTbl(srcTbl)
	local ret = {}
	for idx, v in pairs(srcTbl) do
		ret[v] = true
	end
	return ret
end

function getPtoListTbl(srcTbl)
	local ret = {}
	for idx, v in pairs(srcTbl) do
		ret[v] = idx
	end
	return ret
end

function getPtoKeyTbl(srcTbl)
	local ret = {}
	for _, info in pairs(srcTbl) do
		ret[info.k] = info.v
	end
	return ret
end

function getDelKeyTbl(allTbl, curTbl)
	local ret = {}
	for key, _ in pairs(allTbl) do
		if not curTbl[key] then
			ret[key] = true
		end
	end
	return ret
end

function serialize(t) -- 只支持 number 或 string 做 key ，但是 value 可以是一个 table ，并支持循环引用
	local mark={}
	local assign={}
	
	local function ser_table(tbl,parent)
		mark[tbl]=parent
		local tmp={}
		for k,v in pairs(tbl) do
			local keyType = type(k)
			local valueType = type(v)

			local key = k
			if keyType=="number" then
				key = string.format('[%s]', k)
			elseif keyType=="string" and tonumber(k) then
				key = string.format('[\"%s\"]', k)
			end

			if valueType=="table" then
				local dotkey= parent..(keyType=="number" and key or "."..key)
				if mark[v] then
					local ele = string.format('%s=%s', dotkey,mark[v])
					table.insert(assign,ele)
				else
					table.insert(tmp, key.."="..ser_table(v,dotkey))
				end
			elseif valueType == "string" then
				if string.find(v, '^do local ret') then
					local ele = string.format('%s=[[%s]]', key,v)
					table.insert(tmp, ele)
				else
					local ele = string.format('%s=\"%s\"', key,v)
					table.insert(tmp, ele)
				end
			elseif valueType == "boolean" then
				local ele = string.format('%s=%s', key,tostring(v))
				table.insert(tmp, ele)
			else
				local ele = string.format('%s=%s', key,v)
				table.insert(tmp, ele)
			end
		end
		return string.format('{%s}', table.concat(tmp,","))
	end
 	return string.format('do local ret=%s%s return ret end', ser_table(t,"ret"), table.concat(assign," "))
end


function unserialize(str)
	str = string.gsub(str, "\n", "<br/>")
	str = string.gsub(str, "\r", "<br/>")

	local ret = loadstring(str)
	if ret then
		setfenv(ret, {})
		return ret()
	end
end

function splitUtf8Str( str )
	local tab = {}
	for uchar in string.gfind(str, "[%z\1-\127\194-\244][\128-\191]*") do tab[#tab+1] = uchar end
	return tab
end

function toPositiveRadian(r)
	return r < 0 and (2 * math.pi + r) or r
end
function getRadian(x, y)
	local r = math.atan2(y, x)
	return toPositiveRadian(r)
end

function radian2Degree(r)
	return 180 * r / math.pi 
end

function getDegreeBy2Point(sx, sy, dx, dy)
	local rad = getRadian(dx-sx, dy-sy)
	return radian2Degree(rad)
end

--[[
	deg:
		0 right
		90 up
		180 left
		270 down
]]
function getDirByDegree(deg)
	if deg == 0 then return 0, 1 end
	local rad = degree2Radian(deg)
	return math.cos(rad), math.sin(rad)
end

function getUtf8Char(text, index)
	local charTbl = splitUtf8Str(text)
	return charTbl[index]
end

function getUtf8WorldCount(text)
	local charTbl = splitUtf8Str(text)
	return #charTbl
end

function getUtf8ByteCount(text)
	local charTbl = splitUtf8Str(text)
	local count = 0
	for i, c in ipairs(charTbl) do
		local l = COMMON_FUNC.calCharLength(c)
		count = count + l
	end
	return count
end

function isCJKCode(chInt)
	-- (0x2E80 -- 0x2FDF) -- CJK Radicals Supplement & Kangxi Radicals
	-- (0x2FF0 -- 0x30FF) -- Ideographic Description Characters, CJK Symbols and Punctuation & Japanese
	-- (0x3100 -- 0x31BF) -- Korean
	-- (0x31C0 -- 0x4DFF) -- Other extensions
	-- (0x4E00 -- 0x9FBF) -- CJK Unified Ideographs
	-- (0xAC00 -- 0xD7AF) -- Hangul Syllables
	-- (0xF900 -- 0xFAFF) -- CJK Compatibility Ideographs
	-- (0xFE30 -- 0xFE4F) -- CJK Compatibility Forms
	return (chInt >= 14858880 and chInt <= 14860191)
		or (chInt >= 14860208 and chInt <= 14910399)
		or (chInt >= 14910592 and chInt <= 14911167)
		or (chInt >= 14911360 and chInt <= 14989247)
		or (chInt >= 14989440 and chInt <= 15318719)
		or (chInt >= 15380608 and chInt <= 15572655)
		or (chInt >= 15705216 and chInt <= 15707071)
		or (chInt >= 15710384 and chInt <= 15710607)
end

function isOtherCode(chInt)
	-- latin 德语，法语，越南语，土耳其
	-- 0080-00FF：C1控制符及拉丁文补充-1 (C1 Control and Latin 1 Supplement)
	-- 0100-017F：拉丁文扩展-A (Latin Extended-A)
	-- 0180-024F：拉丁文扩展-B (Latin Extended-B)
	-- 0250-02AF：国际音标扩展 (IPA Extensions)
	-- 1E00-1EFF：拉丁文扩充附加 (Latin Extended Additional)
	if (chInt >= 49825 and chInt <= 51871) 
		or (chInt >= 14792832 and chInt <= 14793663) then 
		return true
	end

	-- 俄语
	-- 0400-04FF：西里尔字母(Cyrillic)
	-- 0500-051F：西里尔字母补充 (Cyrillic Supplement)
	-- 0520-052F：分数和卡通电池 (Fraction and Cartoon Battery)
	if (chInt >= 53376 and chInt <= 54207)
		or (chInt >= 54400 and chInt <= 54431)
		or (chInt >= 54432 and chInt <= 54447) then 
		return true 
	end

	-- 0E00-0E7F：泰文 (Thai)
	if (chInt >= 14727296 and chInt <= 14727615) then 
		return true 
	end

	-- 0600-06FF：阿拉伯文 (Arabic)
	-- 0750-077F：阿拉伯文补充 (Arabic Supplement)
	if (chInt >= 55424 and chInt <= 56255)
		or (chInt >= 56976 and chInt <= 56767) then
		return true 
	end
	return false
end

local function isChCode(chInt)
	-- (0x4E00 -- 0x9FA5) --  base chinese 
	if (chInt >= 14989440 and chInt <= 15318693) then
		return true
	end
	return false
end

function stringToChars(str)
	local list = {}
	local len = string.len(str)
	local i = 1
	while i <= len do
		local c = string.byte(str, i)
		local shift = 1
		if c > 0 and c <= 127 then
			shift = 1
		elseif (c >= 192 and c <= 223) then
			shift = 2
		elseif (c >= 224 and c <= 239) then
			shift = 3
		elseif (c >= 240 and c <= 247) then
			shift = 4
		end
		local char = string.sub(str, i, i+shift-1)
		i = i + shift
		table.insert(list, char)
	end
	return list, len
end

local function getCharCode(str)
	local chInt = 0
	local len = string.len(str)
	for i = 1, len do
		local n = string.byte(str, i)
		chInt = chInt * 256 + n
	end
	return chInt
end

function isChStr(str)
	local charList = stringToChars(str)
	for _, char in ipairs(charList) do
		local chInt = getCharCode(char)
		if not isChCode(chInt) then
			return fasle
		end
	end
	return true
end

function calStrLength(str)
	local charList = stringToChars(str)
	local length = 0
	for _, char in ipairs(charList) do
		local chInt = getCharCode(char)
		if isCJKCode(chInt) then 
			length = length + 2
		else 
			length = length + 1
		end
	end
	return length
end

function calCharLength(char)
	local length = 0
	local chInt = getCharCode(char)
	if isCJKCode(chInt) then 
		length = length + 2
	else 
		length = length + 1
	end
	return length
end

local function checkCharCode(char)
	if (char >= 'a' and char <= 'z') or (char >= 'A' and char <= 'Z') or (char >= '0' and char <= '9') then
		return true
	end

	local chInt = getCharCode(char)
	if chInt == 14909568 then -- 全角空格
		return false
	end
	if chInt == 14910884 then --朝鲜文空格
		return false
	end
	if isCJKCode(chInt) then
		return true
	end
	if isOtherCode(chInt) then
		return true
	end
	return false
end

function isContainEscapeChar(str)
	local charList = stringToChars(str)
	for _, char in ipairs(charList) do
		if not checkCharCode(char) then
			return true
		end
	end
	return false
end

function getLanguageFmtDataByTbl(tbl)
	local function formatLanTbl(tbl, cnt)
		cnt = cnt + 1
		assert(cnt < 100)
		local convTbl = {}
		for _, langData in ipairs(tbl) do
			if type(langData) == "table" then
				table.insert(convTbl, formatLanTbl(langData, cnt))
			else
				table.insert(convTbl, langData)
			end
		end

		local langId = table.remove(convTbl, 1)
		local langData = LANGUAGE.getStringById(tonumber(langId))

		if langData.Order then
			local orderArg = {}
			for idx,order in ipairs(langData.Order) do
				table.insert(orderArg, convTbl[order])
			end
			return string.format(langData.Txt, unpack(orderArg))
		else
			return string.format(langData, unpack(convTbl))
		end
	end
	return formatLanTbl(tbl, 0)
end

function getLanguageFmtData(str)
	if string.find(str, '^do local ret') then
		local retTbl = unserialize(str)
		if retTbl then
			return getLanguageFmtDataByTbl(retTbl)
		end
	end
	return str
end

function convertToClientPos(x, z)
	return x / posResolution, z / posResolution
end
function calTileCenterPosByTilePos(tilex, tilez)
	local srvx = tilex * tileWidth + math.floor(tileWidth / 2) - 1
	local srvz = tilez * tileWidth + math.floor(tileWidth / 2) - 1
	return srvx, srvz
end

userAreaAOI = 1000
npcCityAOI = 8000
defAOI = 0
forceAOI = 0
varmyAOI = 0
charAOI = 0
resPointAOI = 0

function calEntityRect(srvx, srvz, hw, hh)
	local halfw = hw
	local halfh = hh
	local left = srvx - halfw
	local bottom = srvz - halfh
	local right = srvx + halfw
	local top = srvz + halfh
	assert(left >= 0)
	assert(bottom >= 0)
	return left, bottom, right, top
end

rtsHexSize = 10 * 100

local sq3 = math.sqrt(3)
function offHexGridToCPos(gx, gz)
	local param = 1
	if (gz % 2 == 0) then
		param = 0
	end

	local retx = math.floor(rtsHexSize * sq3 * (gx + 0.5 * (param)))
	local retz = math.floor(rtsHexSize * 1.5 * gz)
	return retx, retz
end

function offHexGridCorner(cx, cy, i)
	local angle_deg = 60 * i - 30
	local angle_rad = math.pi / 180 * angle_deg
	local retx = math.floor(cx + rtsHexSize * math.cos(angle_rad))
	local retz = math.floor(cy + rtsHexSize * math.sin(angle_rad))
	return retx, retz
end

function cubeToOffHex(cube)
	local param = 1
	if (cube.s % 2 == 0) then
		param = 0
	end
	local gx = (cube.q + (cube.s - (param)) / 2)
	local gz = (cube.s)
	gz = gz == 0 and 0 or gz -- -0 => 0
	return gx, gz
end

function offHexToCube(gx, gz)
	local param = 1
	if (gz % 2 == 0) then
		param = 0
	end
	local x = gx - (gz - (param)) / 2
	local z = gz
	local y = -x-z
	return {
		q = x,
		r = y,
		s = z,
	}
end

local function cubeDis(a, b)
	return (math.abs(a.q - b.q) + math.abs(a.r - b.r) + math.abs(a.s - b.s)) / 2
end

local function cubeAdd(a, b)
	return {
		q = a.q + b.q,
		r = a.r + b.r,
		s = a.s + b.s,
	}
end

local function maxv(v1, v2)
	if v1 > v2 then
		return v1
	else
		return v2
	end
end
local function minv(v1, v2)
	if v1 < v2 then
		return v1
	else
		return v2
	end
end

function calGridCenterPosByCPos(x, z)
	local gx, gz = offHexCPosToGrid(x, z)
	return offHexGridToCPos(gx, gz)
end

local function isValidRange(sgx, sgz, gx, gz, noCenter)
	if not noCenter then
		return true
	end
	if (sgx == gx) and (sgz == gz) then
		return false
	end
	return true
end

local function isInRingRange(curRange, minRange)
	if not minRange then
		return true
	end
	if curRange > 0 then
		if curRange > minRange then
			return true
		end
	elseif curRange < 0 then
		if (-curRange) > (-minRange) then
			return true
		end
	end
	return false
end

function calHexCntByRange(sgx, sgz, range, noCenter)
	local cnt = 0
	local center = offHexToCube(sgx, sgz)

	for x = -range, range do
		local sz = maxv(-range, -x-range)
		local tz = minv(range, -x+range)
		assert(tz >= sz)
		for z = sz, tz do
			local y = -x-z
			local res = cubeAdd(center, {
				q = x,
				r = y,
				s = z,
			})
			local gx, gz = cubeToOffHex(res)
			if isValidRange(sgx, sgz, gx, gz, noCenter) then
				cnt = cnt + 1
			end
		end
	end
	return cnt
end

function offHexRange(sgx, sgz, range, noCenter)
	local center = offHexToCube(sgx, sgz)

	local resList = {}
	local resTbl = {}
	for x = -range, range do
		local sz = maxv(-range, -x-range)
		local tz = minv(range, -x+range)
		assert(tz >= sz)
		for z = sz, tz do
			local y = -x-z
			local res = cubeAdd(center, {
				q = x,
				r = y,
				s = z,
			})
			local gx, gz = cubeToOffHex(res)
			if isValidRange(sgx, sgz, gx, gz, noCenter) then
				if not resTbl[gx] then
					resTbl[gx] = {}
				end
				resTbl[gx][gz] = true
				table.insert(resList, {
					gx = gx,
					gz = gz,
				})
			end
		end
	end
	return resList, resTbl
end

local function cubeSub(a, b)
	return {
		q = a.q - b.q,
		r = a.r - b.r,
		s = a.s - b.s,
	}
end

function calHexDirection(centerGx, centerGz, gx, gz)
	local center = offHexToCube(centerGx, centerGz)
	local tar = offHexToCube(gx, gz)
	local res = cubeSub(tar, center)
	if (res.q >= 0) and (res.s > 0) and (res.r < 0) then
		return COMMON_CONST.HEX_DIRECTION.TOP_RIGHT
	end
	if (res.q < 0) and (res.s > 0) and (res.r <= 0) then
		return COMMON_CONST.HEX_DIRECTION.TOP
	end
	if (res.q < 0) and (res.s >= 0) and (res.r > 0) then
		return COMMON_CONST.HEX_DIRECTION.TOP_LEFT
	end
	if (res.q <= 0) and (res.s < 0) and (res.r > 0) then
		return COMMON_CONST.HEX_DIRECTION.BOTTOM_LEFT
	end
	if (res.q > 0) and (res.s < 0) and (res.r >= 0) then
		return COMMON_CONST.HEX_DIRECTION.BOTTOM
	end
	if (res.q > 0) and (res.s <= 0) and (res.r < 0) then
		return COMMON_CONST.HEX_DIRECTION.BOTTOM_RIGHT
	end

end

function offVaildHexRange(sgx, sgz, range, noCenter, checkFunc)
	local center = offHexToCube(sgx, sgz)

	local resList = {}
	local resTbl = {}
	for x = -range, range do
		local sz = maxv(-range, -x-range)
		local tz = minv(range, -x+range)
		assert(tz >= sz)
		for z = sz, tz do
			local y = -x-z
			local res = cubeAdd(center, {
				q = x,
				r = y,
				s = z,
			})
			local gx, gz = cubeToOffHex(res)
			if isValidRange(sgx, sgz, gx, gz, noCenter) then
				if checkFunc(gx, gz) then
					if not resTbl[gx] then
						resTbl[gx] = {}
					end
					resTbl[gx][gz] = true
					table.insert(resList, {
						gx = gx,
						gz = gz,
					})
				end
			end
		end
	end
	return resList, resTbl
end

local function cubeScale(hex, f)
	return {
		q = hex.q * f,
		r = hex.r * f,
		s = hex.s * f,
	}
end

local function cubeRing(center, radius)
	local sOff = NEIGHBOR_OFFSET[5]
	local resList = {}
	local resTbl = {}
	local hex = cubeAdd(center, cubeScale({q = sOff[1], r = sOff[2], s = sOff[3]}, radius))
	for i = 1, 6 do
		for j=1, radius do
			local off = NEIGHBOR_OFFSET[i]
			local tCube = {
				q = off[1],
				r = off[2],
				s = off[3],
			}
			local cube = cubeAdd(hex, tCube)
			hex = cube
			local gx, gz = cubeToOffHex(cube)
			table.insert(resList, {gx = gx, gz = gz})
			if not resTbl[gx] then
				resTbl[gx] = {}
			end
			resTbl[gx][gz] = true
		end
	end
	return resList, resTbl
end

function getRingByDis(gx, gz, range)
	local center = offHexToCube(gx, gz)
	return cubeRing(center, range)
end

function getRingTblByRange(gx, gz, range)
	local resTbl = {}
	for r = 1, range do
		if not resTbl[r] then
			resTbl[r] = {}
		end
		local list = getRingByDis(gx, gz, r)
		resTbl[r] = list
	end
	return resTbl
end

function getRingTbl(gx, gz, srcRange, tarRange)
	local resTbl = {}
	for r = srcRange, tarRange do
		if not resTbl[r] then
			resTbl[r] = {}
		end
		local list = getRingByDis(gx, gz, r)
		resTbl[r] = list
	end
	return resTbl
end

function getRingList(gx, gz, range)
	local center = offHexToCube(gx, gz)

	local resList = {}
	for q=-range,range do
		for r=math.max(-range,-q-range),math.min(range,-q+range) do
			local s = -q-r
			local cube = cubeAdd(center, {q=q,r=r,s=s})
			table.insert(resList, {cubeToOffHex(cube)})
		end
	end

	return resList
end

function getGridIncircleRadius(gridRadius)
	return gridRadius * 1.5 * rtsHexSize
end

function offHexDis(sgx, sgz, tgx, tgz)
	local scube = offHexToCube(sgx, sgz)
	local tcube = offHexToCube(tgx, tgz)
	return cubeDis(scube, tcube)
end

local function round(v)
	return math.floor(v + 0.5)
end

local function hexRound(h)
	local q = round(h.q)
	local r = round(h.r)
	local s = round(h.s)
	local q_diff = math.abs(q - h.q)
	local r_diff = math.abs(r - h.r)
	local s_diff = math.abs(s - h.s)
	if (q_diff > r_diff and q_diff > s_diff) then
		q = -r - s
	elseif (r_diff > s_diff) then
		r = -q - s
	else
		s = -q - r
	end
	return {
		q = q,
		r = r,
		s = s,
	}
end

function cposToCube(x, z)
	if not x or not z then
		print("convert pos error ", debug.traceback())
	end
	local q = ((sq3/3 * x  -  1/3 * z) / rtsHexSize)
	local s = ((2/3 * z) / rtsHexSize)
	local r = -q - s
	local hex = {
		q = q,
		r = r,
		s = s,
	}
	hex = hexRound(hex)
	return hex
end

function offHexCPosToGrid(x, z)
	local hex = cposToCube(x, z)
	return cubeToOffHex(hex)
end

function degree2Radian(d)
	return math.pi * d / 180
end

function rtsValidGPos(gx, gz)
	if gx < 0 or gx >= xmaxTileCnt or gz < 0 or gz >= zmaxTileCnt then
		return false
	end
	return true
end

function calRectDist(sx, sz, tx, tz )
	local dx = tx - sx
	local dz = tz - sz
	return math.ceil(math.sqrt(dx * dx + dz * dz))
end

NEIGHBOR_OFFSET = {
	{1, 0, -1},
	{1, -1, 0},
	{0, -1, 1},
	{-1, 0, 1},
	{-1, 1, 0},
	{0, 1, -1},
}

function getNeighborGrid(gx, gz)
	local cube = offHexToCube(gx, gz)
	local ret = {}
	for _, info in pairs(NEIGHBOR_OFFSET) do
		local tmp = {
			q = cube.q + info[1],
			r = cube.r + info[2],
			s = cube.s + info[3],
		}
		local gx,gz = cubeToOffHex(tmp)
		if not ret[gx] then
			ret[gx] = {}
		end
		ret[gx][gz] = true
	end
	return ret
end

function calGridByCubeOffset(gx, gz, offCube)
	local cube = offHexToCube(gx, gz)
	local res = cubeAdd(cube, offCube)
	return cubeToOffHex(res)
end

local TOPLEFT_OFF = {
	{0, -1, 1},
	{-1, 0, 1},
	{-1, 1, 0},
}

function getTopLeftGrid(ogx, ogz)
	local cube = offHexToCube(ogx, ogz)
	local ret = {}
	for _, info in pairs(TOPLEFT_OFF) do
		local tmp = {
			q = cube.q + info[1],
			r = cube.r + info[2],
			s = cube.s + info[3],
		}
		local gx, gz = cubeToOffHex(tmp)
		table.insert(ret, {
			gx = gx,
			gz = gz,
		})
	end
	return ret
end

COOR_PATTERN = "%(%s*[0-9]+%s*,%s*[0-9]+%s*%)"
--分解字符串，以便屏蔽词检查
function splitMsgToSWTbl(msg)
	local msgTbl = {}
	local len = string.len(msg)
	local sPos = 1
	local i, j = string.find(msg, COOR_PATTERN, sPos)
	while(i) do
		if i > sPos then
			table.insert(msgTbl, {k = string.sub(msg, sPos, i-1), v = COMMON_CONST.CHAT_SENSITIVE_TYPE.FILT})
		end
		table.insert(msgTbl, {k = string.sub(msg, i, j), v = COMMON_CONST.CHAT_SENSITIVE_TYPE.NONE})
		sPos = j + 1
		i, j = string.find(msg, COOR_PATTERN, sPos)
	end
	if sPos <= len then
		table.insert(msgTbl, {k = string.sub(msg, sPos, len), v = COMMON_CONST.CHAT_SENSITIVE_TYPE.FILT})
	end
	return msgTbl
end


local luaSpecialChar = { ["^"] = true, ["$"] = true, ["("] = true, [")"] = true, ["%"] = true, ["."] = true, ["["] = true, ["]"] = true, ["*"] = true, ["+"] = true, ["-"] = true, ["?"] = true}
function filterChatCharacters2(msg)
	local origMsg = msg
	local replaceInfo = {}
	
	local allFilterCharData = {
		[" "] = true,
	}
	
	for char, _ in pairs(allFilterCharData) do
		if char ~= "" then
			local tChar = char
			if luaSpecialChar[char]	then
				tChar = "%" .. char
			end
			local p, e, c = string.find(msg, tChar, 1)
			while p and p <= #msg do
				table.insert(replaceInfo, {
					p = p,
					c = char 
				})
				p, _, c = string.find(msg, tChar, p+1)
			end
		end
	end

	for char, _ in pairs(allFilterCharData) do
		if luaSpecialChar[char]	then
			char = "%" .. char
		end
		msg = string.gsub(msg, char, "")
	end
	return msg, origMsg, replaceInfo
end
------------------------------------------------
function initSurroundRec(pfid, heroType, rate, fightId)
	return {
		eventType = COMMON_CONST.BEVENT_TYPE_SURROUND,
		eventNum = {
			heroType,
			rate * 100,
			fightId,
		},
		eventStr = {
			pfid,
		},
		eventStrNum = {},
	}
end

function initStatusRec(pfid, heroType, status, rate, fightId)
	return {
		eventType = COMMON_CONST.BEVENT_TYPE_STATUS,
		eventNum = {
			heroType,
			status,
			rate,
			fightId,
		},
		eventStr = {
			pfid,
		},
		eventStrNum = {},
	}
end

function initBuffRec(pfid, tfid, heroType, skillType, skillLevel, valTbl, fightId)
	local eventNum = {
		heroType,
		skillType,
		skillLevel,
		fightId,
	}

	return {
		eventType = COMMON_CONST.BEVENT_TYPE_BUFF,
		eventNum = eventNum,
		eventStr = {
			pfid,
			tfid,
		},
		eventStrNum = valTbl,
	}
end

function initHpRec(pfid, tfid, heroType, skillType, hp, fightId)
	return {
		eventType = COMMON_CONST.BEVENT_TYPE_HP,
		eventNum = {
			heroType,
			skillType,
			hp,
			fightId,
		},
		eventStr = {
			pfid,
			tfid,
		},
		eventStrNum = {},
	}
end

function initHarmRec(pfid, tfid, heroType, skillType, harm, fightId)
	return {
		eventType = COMMON_CONST.BEVENT_TYPE_HARM,
		eventNum = {
			heroType,
			skillType,
			harm,
			fightId,
		},
		eventStr = {
			pfid,
			tfid,
		},
		eventStrNum = {},
	}
end

function initBattleCBHarmRec(tfid, harm)
	return {
		eventType = COMMON_CONST.BEVENT_TYPE_CBHARM,
		eventNum = {
			harm,
		},
		eventStr = {
			tfid,
		},
		eventStrNum = {},
	}
end

function initPrepareEndRec(fightId)
	return {
		eventType = COMMON_CONST.BEVENT_TYPE_PREEND,
		eventNum = {
			fightId,
		},
		eventStr = {},
		eventStrNum = {},
	}
end

function initCrossbowHarmRec(harm, leaderType, curHp, gx, gz, time)
	return {
		leaderType = leaderType,
		eventType = COMMON_CONST.REALTIME_REC_TYPE.CROSSBOW_ATT,
		eventNum = {
			leaderType,
			harm,
			curHp,
			gx,
			gz,
			time,
		},
		eventStr = {},
		eventStrNum = {},
	}
end

function initTriggerTrapRec(leaderType, gx, gz, buffSec, time)
	return {
		leaderType = leaderType,
		eventType = COMMON_CONST.REALTIME_REC_TYPE.TRAP_TRIGGER,
		eventNum = {
			leaderType,
			gx,
			gz,
			time,
			buffSec,
		},
		eventStr = {},
		eventStrNum = {},
	}
end

function randomShuffleList(list)
	local ret = {}
	local totalCnt = #list	
	local oldCnt = totalCnt
	for i=1, oldCnt do
		local idx = math.random(1, #list)
		local che = list[idx]
		list[idx] = list[totalCnt]
		list[totalCnt] = nil
		table.insert(ret, che)
		totalCnt = totalCnt - 1
	end
	assert(#ret == oldCnt)
	return ret
end

function randKeyByKeyRateTbl(keyRateTbl)
	local sumRate = 0
	for k, r in pairs(keyRateTbl) do
		sumRate = sumRate + r
	end
	local randNum = math.random(1, sumRate)
	local curNum = 0
	for k, r in pairs(keyRateTbl) do
		curNum = curNum + r
		if randNum <= curNum then
			return k
		end
	end
end

function getUnionMaxMemSize()
	return 45
end

function genRwdShowInfo(rewardType, itemType, itemCount, rewardReason)
	return {
		reward_type = rewardType,
		item_type = itemType,
		item_count = itemCount,
		reward_reason = rewardReason or 0,
	}
end

function genRewardInfo(rewardType, itemType, itemCount)
	return {
		reward_type = rewardType,
		item_type = itemType,
		item_count = itemCount,
	}
end

function multiRewardInfo(rewardInfo, cnt)
	return {
		reward_type = rewardInfo.reward_type,
		item_type = rewardInfo.item_type,
		item_count = rewardInfo.item_count * cnt,
	}
end

function multiRewardList(rewardList, factor)
	local tbl = {}
	for _, info in pairs(rewardList) do
		if not tbl[info.reward_type] then
			tbl[info.reward_type] = {}
		end
		if not tbl[info.reward_type][info.item_type] then
			tbl[info.reward_type][info.item_type] = {count = 0 }
		end
		local tempInfo = tbl[info.reward_type][info.item_type]
		tempInfo.count = tempInfo.count + info.item_count * factor
	end
	local ret = {}
	for rewardType, info in pairs(tbl) do
		for itemType, tempInfo in pairs(info) do
			table.insert(ret, genRewardInfo(rewardType, itemType, tempInfo.count))
		end
	end
	return ret
end

function mergeRewardList(rewardList1, rewardList2)
	local tbl = {}
	for _, info in pairs(rewardList1) do
		if not tbl[info.reward_type] then
			tbl[info.reward_type] = {}
		end
		if not tbl[info.reward_type][info.item_type] then
			tbl[info.reward_type][info.item_type] = {count = 0 }
		end
		local tempInfo = tbl[info.reward_type][info.item_type]
		tempInfo.count = tempInfo.count + info.item_count
	end
	for _, info in pairs(rewardList2) do
		if not tbl[info.reward_type] then
			tbl[info.reward_type] = {}
		end
		if not tbl[info.reward_type][info.item_type] then
			tbl[info.reward_type][info.item_type] = {count = 0 }
		end
		local tempInfo = tbl[info.reward_type][info.item_type]
		tempInfo.count = tempInfo.count + info.item_count
	end

	local ret = {}
	for rewardType, info in pairs(tbl) do
		for itemType, tempInfo in pairs(info) do
			table.insert(ret, genRewardInfo(rewardType, itemType, tempInfo.count))
		end
	end
	return ret
end

function mergeRwdShowList(rewardList1, rewardList2)
	local tbl = {}
	for _, info in pairs(rewardList1) do
		if not tbl[info.reward_type] then
			tbl[info.reward_type] = {}
		end
		local t = tbl[info.reward_type]
		if not t[info.item_type] then
			t[info.item_type] = {}
		end
		local rewardReason = info.reward_reason or COMMON_CONST.REWARD_FLOW_REASON.NORMAL
		local tt = t[info.item_type]
		if not tt[rewardReason] then
			tt[rewardReason] = {count = 0,}
		end	
		local tempInfo = tt[rewardReason]
		tempInfo.count = tempInfo.count + info.item_count
	end
	for _, info in pairs(rewardList2) do
		if not tbl[info.reward_type] then
			tbl[info.reward_type] = {}
		end
		local t = tbl[info.reward_type]
		if not t[info.item_type] then
			t[info.item_type] = {}
		end
		local rewardReason = info.reward_reason or COMMON_CONST.REWARD_FLOW_REASON.NORMAL
		local tt = t[info.item_type]
		if not tt[rewardReason] then
			tt[rewardReason] = {count = 0,}
		end	
		local tempInfo = tt[rewardReason]
		tempInfo.count = tempInfo.count + info.item_count
	end

	local ret = {}
	for rewardType, itemInfo in pairs(tbl) do
		for itemType, info in pairs(itemInfo) do
			for rewardReason, tempInfo in pairs(info) do
				table.insert(ret, genRwdShowInfo(rewardType, itemType, tempInfo.count, rewardReason))
			end
		end
	end
	return ret
end

function getEventCustomKey(userId, value)
	return string.format("%s_%s", userId, value)
end

function calTimeByGold(goldCnt)
	return goldCnt * DATA_CONST.getValueByKey(2145)
end

function calNeedGoldBySubSec(subSec)
	return 1 * math.ceil(subSec / calTimeByGold(1))
end

function calSubFreeTimeNeedGold(subSec)
	if subSec < DATA_CONST.getValueByKey(2140) then
		return 0
	end
	local leftTime = subSec - DATA_CONST.getValueByKey(2140)
	return calNeedGoldBySubSec(leftTime)
end

function isUnLockSkill(skillType, star)
	local skillInfo = DATA_SKILL.getSkillInfoByType(skillType)
	local limitTbl = skillInfo.Limit
	if limitTbl.STAR and star < limitTbl.STAR then
		return false
	end
	return true
end

local kindHarmTbl = {
	[COMMON_CONST.SOLDIER_KIND_RIDER] = {
		[COMMON_CONST.SOLDIER_KIND_FOOT] = true,
	},
	[COMMON_CONST.SOLDIER_KIND_FOOT] = {
		[COMMON_CONST.SOLDIER_KIND_ARROW] = true,
	},
	[COMMON_CONST.SOLDIER_KIND_ARROW] = {
		[COMMON_CONST.SOLDIER_KIND_RIDER] = true,
	}
}

function isRestrainKind(sKind, tSKind)
	return kindHarmTbl[sKind][tSKind]
end

function isBeRestrainKind(sKind, tSKind)
	return kindHarmTbl[tSKind][sKind]
end

function calHeroPolRate(pol, attrBuff)
	local effectAdd = DATA_POLHERO.getPolHeroEffectAdd(attrBuff)
	return pol * effectAdd
end

function hasElement(tbl)
	local k, v = next(tbl, nil)
	if not k then
		return false
	end
	return true
end

function getNpcDefOrder(config)
	local ret = {}
	for sIdx, cnt in pairs(config) do
		for _ = 1, cnt do
			table.insert(ret, sIdx)
		end
	end
	local size = #ret
	for i, sIdx in ipairs(ret) do
		local switchIdx = ((sIdx + i) ^ 2) % size + 1
		ret[i], ret[switchIdx] = ret[switchIdx], ret[i]
	end
	return ret
end

function calAPAddPoint(time)
	local conf = DATA_CONST.getValueByKey(2132)
	return math.floor(time / conf[1]) * conf[2]
end

function getHeroAttrValueAndLevRate(attrType, heroType)
	local info = DATA_HERO_BASE.getHeroInfoByType(heroType)
	local value, addRate
	if attrType == COMMON_CONST.HERO_ATTR.FORCE then
		value = "Force"
		addRate = "AddForce"
	elseif attrType == COMMON_CONST.HERO_ATTR.DEFENCE then
		value = "Def"
		addRate = "AddDef"
	elseif attrType == COMMON_CONST.HERO_ATTR.COMMAND then
		value = "Com"
		addRate = "AddCom"
	end
	return info[value], info[addRate]
end

function calHeroAttrValueByType(attrType, heroType, grade, weaponAdd, starAdd)
	local base, addRate = getHeroAttrValueAndLevRate(attrType, heroType)
	local factor = COMMON_CONST.ATTR_FACTOR
	local ret = base * factor + addRate * grade * factor + weaponAdd * factor + starAdd * factor
	return math.floor(ret) / factor 
end

function convertHeroAttrValue(val)
	return math.floor(val * COMMON_CONST.ATTR_FACTOR) / COMMON_CONST.ATTR_FACTOR
end

function calPopRate(pop)
	return 0.5 * math.pow(pop, 0.5) + 0.5
end

function calPhyAttRate(power)
	return 0.0008 * math.pow(power, 2) + 0.0931 * power
end

function calMagAttRate(wis)
	return 0.0008 * math.pow(wis, 2) + 0.0931 * wis
end

function calDefRate(def)
	return 0.0008 * math.pow(def, 2) + 0.0931 * def
end

function isNpcId(userId)
	return userId == COMMON_CONST.NPC_USER_ID
end

function calTransNeedBaseSoldier(sType, sCnt)
	local sLevel = DATA_SOLDIER.getSLvByType(sType)
	local singCnt = DATA_SOLDIER_KIND.getCostBaseSCnt(sLevel)
	return math.ceil(singCnt * sCnt)
end

function getCitySubPos(cityType, cx, cz, pidx)
	local pinfo = DATA_NPCCITY.getLayoutPlayerPos(cityType, pidx)
	local clientx = pinfo[1]
	local clientz = pinfo[2]
	local srvx, srvz = convertToSrvPos(clientx, clientz)
	return (cx + srvx), (cz + srvz)
end

function calHurtAndDead(subCnt, hurtRate, backRate, deadRate)
	local hurtCnt = 0
	local deadCnt = 0
	local backCnt = 0
	if subCnt > 0 then
		if deadRate then
			deadCnt = math.ceil(subCnt * deadRate)
			if deadCnt > subCnt then
				deadCnt = subCnt
			end
			hurtCnt = math.ceil(subCnt * hurtRate)
			if hurtCnt + deadCnt > subCnt then
				hurtCnt = subCnt - deadCnt
			end
			backCnt = subCnt - deadCnt - hurtCnt
		else
			hurtCnt = math.ceil(subCnt * hurtRate)
			if hurtCnt > subCnt then
				hurtCnt = subCnt
			end
			backCnt = math.ceil(subCnt * backRate)
			if hurtCnt + backCnt > subCnt then
				backCnt = subCnt - hurtCnt
			end
			deadCnt = subCnt - hurtCnt - backCnt
		end
	end
	return hurtCnt, deadCnt, backCnt
end

function checkTableEqual(tbl1, tbl2)
	if table.size(tbl1) ~= table.size(tbl2) then
		return false
	end
	for k, v in pairs(tbl1) do
		if type(v) == "table" then
			if not tbl2[k] or type(tbl2[k]) ~= "table" then
				return false
			end
			return checkTableEqual(v, tbl2[k])
		else
			if tbl2[k] ~= v then
				return false
			end
		end
	end
	return true
end

function calForceMaxSCnt(baseCnt, heroRate)
	if not baseCnt then
		baseCnt = 1000
	end
	local ret = math.ceil(baseCnt * (1 + heroRate))
	return tonumber(string.format("%.0f",ret))
end

function calMoveFrame(dis, speed)
	return math.ceil(dis / (speed * COMMON_FUNC.timeStep))
end

function calTiredDebuff(tired)
	local debuff = math.floor(tired / DATA_CONST.getValueByKey(2235)) * DATA_CONST.getValueByKey(2239)
	local max = DATA_CONST.getValueByKey(2240)
	return math.min(max, debuff)
end

function randomList(list, cnt)
	local copyList = {}
	for _, val in pairs(list) do
		table.insert(copyList, val)
	end

	local maxCnt = #copyList
	if cnt > maxCnt then
		cnt = maxCnt
	end
	local ret = {}
	for i = 1, cnt do
		local idx = math.random(1, maxCnt)
		local val = copyList[idx]
		table.insert(ret, val)

		copyList[idx] = copyList[maxCnt]
		copyList[maxCnt] = nil
		maxCnt = maxCnt - 1
	end
	return ret
end

function isWild(subAreaIdx)
	if subAreaIdx >= 101 and subAreaIdx <= 255 then
		return true
	end
	return false
end

-- 保留n位小数四舍五入
local function keepDecRound(ret, n)
	return math.floor(ret * 10^n + 0.5) / 10^n
end

function calForceRate(defMaxCnt, forceCnt, soldierCnt, a, b)
	local c = DATA_CONST.getValueByKey(2670)
	return a * forceCnt / defMaxCnt + b * math.min(1, (soldierCnt / c))
end

function calChariotHarm(defMaxCnt, sumScnt, sumFcnt, harmBuff)
	local base = DATA_CONST.getValueByKey(2206) * DATA_CONST.getValueByKey(2205)
	local configTbl = DATA_CONST.getValueByKey(2675)
	local a = configTbl.a
	local b = configTbl.b
	local forceRate = calForceRate(defMaxCnt, sumFcnt, sumScnt, a, b)
	return math.ceil(base * (1 + forceRate + harmBuff))
end

function calSLevelAddAttr(sType)
	local sLevel = DATA_SOLDIER.getSLvByType(sType)
	local sKind = DATA_SOLDIER.getSoldierKindByType(sType)
	local bType = COMMON_CONST.SKIND_TO_MILITARY[sKind]
	local bonus = DATA_BUILD_UP.getSoldierBonus(bType, sLevel)
	return bonus
end

function calHeroTrainExp(buildLevel)
	return DATA_BUILD_UP.getTrainExpByLevel(buildLevel)
end

function calUnitTrainExp(sumExp, cnt)
	local rate = DATA_CONST.getValueByKey(2366)[cnt]
	assert(rate)
	return math.ceil(sumExp * (rate / 100))
end

function calTransNeedSoldierToken(sType, cnt)
	return DATA_SOLDIER.getSoldierTokenCost(sType) * cnt
end

function calTransNeedSoldierTokenTbl(sType, cnt)
	local ret = {}
	local costTbl = DATA_SOLDIER.getSoldierTokenTbl(sType)
	for itemType, needCnt in pairs(costTbl) do
		if cnt * needCnt > 0 then
			ret[itemType] = cnt * needCnt
		end
	end
	return ret
end

function tryEraseHighAoi(scene, cgx, cgz, aoiTbl)
	local lower = false
	if not scene:isHigh(cgx, cgz) then
		for gx, info in pairs(aoiTbl) do
			for gz, _ in pairs(info) do
				if scene:isHigh(gx, gz) then
					aoiTbl[gx][gz] = nil
				end
			end
		end
	end
	return aoiTbl
end

local GRD_NPC_RANDOM_TBL = {
	{4,4,2,1,2,2,4,4,1,2,1,1,2,1,2,1},
	{1,2,1,1,4,4,4,1,4,4,1,2},
	{1,2,4,1,2,4,2,2,4,2},
	{2,2,4,4,1,4,4,1,4,1,2,4,4,4,2,2},
	{1,2,2,1,1,4,4,4,2,4,2,1,2,1,4,2},
	{2,2,2,1,4,2,4,1,4,1,2,4,4,1,2,1,1,1},
	{4,2,1,2,4,4,1,1,1,4,4,4,4,2,2,1,4},
	{2,2,1,4,1,2,4,1,2,1,4,1,1,1,2,4,1,4,2},
	{2,2,2,2,2,4,1,2,1,1,2},
	{2,4,4,2,2,4,1,1,2,4,4,4,2,1,2,1,4,2,4,1,2},
	{4,2,1,1,4,4,2,2,4,1,4,2,2,2,4},
}
function getGroundSKind(gx, gz)
	local cnt = #GRD_NPC_RANDOM_TBL
	local index = (gx + gz) % cnt + 1
	local row = GRD_NPC_RANDOM_TBL[index]
	local rowCnt = #row
	index = gz % rowCnt + 1

	return row[index]
end

function getRewardInfoStr(rewardList)
	local ret = {}
	for idx, info in ipairs(rewardList) do
		if info.item_type ~= COMMON_CONST.INVALID_TIME then
			local rewardName = DATA_ITEM.getItemNameByType(info.item_type)
			if idx == 1 then
				table.insert(ret, string.format("%s×%d", rewardName, info.item_count))
			else
				table.insert(ret, string.format("、%s×%d", rewardName, info.item_count))
			end
		end
	end
	return table.concat(ret)
end

function inNightProtect(curHour)
	local conf = DATA_CONST.getValueByKey(2442)
	local startHour = conf[1]
	local endHour = conf[2]
	if startHour <= endHour then
		if (curHour >= startHour)  and (curHour < endHour) then
			return true
		end
	else
		if (curHour >= startHour) or (curHour < endHour) then
			return true
		end
	end
	return false
end

function convertMD5ToHex(md5_code)
        local sign_tbl = {}
        local len = string.len(md5_code)
        for i = 1, len do
                local s = string.sub(md5_code, i, i)                                                                         
                table.insert(sign_tbl, string.format("%02x", string.byte(s)))                                                
        end 
        return table.concat(sign_tbl)
end

function getStrMD5(str, toUpper)
        local md5Str = convertMD5ToHex(lmd5_sum.md5_sum(str, string.len(str)))                                               
        if toUpper then
                return string.upper(md5Str)                                                                                  
        else        
                return md5Str
        end         
end

function getOrgOpenId(account)
	local i = string.find(account, "_")
	local ret = account
	if i then
		string.sub(account, i + 1)
	end
	return ret
end

function genSdkAccount(accType, openid)
	assert(accType)	
	assert(openid)	
	return string.format("%s_%s", COMMON_CONST.ACCOUNT_PREFIX[accType], openid)
end

function isGateRange(subAreaIdx)
	if subAreaIdx >= 0 and subAreaIdx <= 20 then
		return true
	end
	return false
end

function getDefaultFlagSetting()
	return {
		flagIdx = 1,
		markIdx = 3,
		flagRgb = 16,
		staffIdx = 1,
		decorRgb = 4,
		decorIdx = 1,
		markRgb = 4,
		markRgb2 = -1,
		txt = "",
	}
end

function normalize(x, z)
	if x == 0 and z == 0 then
		assert(false)
	end
	local v = math.sqrt(x * x + z * z)
	return x/v, z/v
end

function table_deepcopy( t, d )
        local deep = d or 0 
        if deep > 20 then 
                return
        end  
        local copy = {} 
        for k, v in pairs(t) do 
                if type(v) ~= "table" then 
                        copy[k] = v
                else 
                        copy[k] = table_deepcopy(v, deep + 1) 
                end  
        end  
        return copy 
end

PASS_DIS = 8000

local passGridSize = PASS_DIS/2

function srvToPassGrid(srvx, srvz)
	local gx = math.floor(srvx / passGridSize)
	local gz = math.floor(srvz / passGridSize)
	return gx, gz
end

function passGridToSrv(gx, gz)
	local srvx = gx * (passGridSize) + math.floor(passGridSize/ 2)
	local srvz = gz * (passGridSize) + math.floor(passGridSize/ 2)
	return srvx, srvz
end


local innerGridSize = 200

function srvToInnerGrid(srvx, srvz)
	local gx = math.floor(srvx / innerGridSize)
	local gz = math.floor(srvz / innerGridSize)
	return gx, gz
end

function innerGridToSrv(gx, gz)
	local srvx = gx * (innerGridSize) + math.floor(innerGridSize / 2)
	local srvz = gz * (innerGridSize) + math.floor(innerGridSize / 2)
	return srvx, srvz
end

-- 保留n位小数向上取整
function keepDecCeil(ret, n)
	return math.ceil(ret * 10^n) / 10^n
end

function calForceBuildAtk(sCnt, sType)
	local rate = DATA_CONST.getValueByKey(2684)
	local atk = DATA_SOLDIER.getSoldierBuildAtk(sType)
	return math.ceil(atk * sCnt * rate)
end

function getETypeDimType(eType, level)
	return COMMON_CONST.ETYPE2SIZE[eType].org
end

function mergeItemTbl(dst, src)
	for idx, reward_info in pairs(src) do
		table.insert(dst, reward_info)
	end
end

function testFightChangeSkillValue(skillId, incrRate, field, fieldIncr)
	local skillInfo = DATA_SKILL.getSkillInfoByType(skillId)
	if incrRate ~= -1 then
		for k, v in pairs(skillInfo.triggerRate) do
			skillInfo.triggerRate[k] = v + incrRate
		end
	end
	if field ~= "" then
		for idx, list in pairs(skillInfo.LevelEffect) do
			for lv, info in pairs(list) do
				info[field] = info[field] + fieldIncr	
			end
		end
	end
	--print("=======skillInfo========", skillId, sys.dump(skillInfo.triggerRate), sys.dump(skillInfo.LevelEffect))
end


local rangeW = 1500
local rangeH = 1500
function randomCoor(tx, tz)
	local x = math.random(tx-rangeW, tx+rangeW)
	local z = math.random(tz-rangeH, tz+rangeH)
	return x, z
end

function floorValueByDecimal(value, points)
	local args = 1
	if points >= 1 then
		for i = 1, points do
			args = args * 10
		end
	end
	local i, f = math.modf(value)
	local v = f * args
	local _, ff = math.modf(v)
	if ff > 0.999999 then
		return i + math.ceil(v) / args
	else
		return i + math.floor(v) / args
	end
end

function calAttrRate(value)
	local calTbl = DATA_CONST.getValueByKey(2220)
	local calList = {}
	for k, v in pairs(calTbl) do
		table.insert(calList, {
			k = k,
			v = v,
		})
	end
	table.sort(calList, function(a, b)
		return a.k < b.k
	end)
	local ret = 0
	local tag = false
	for idx, info in ipairs(calList) do
		local rate = info.v
		if info.k >= value then
			tag = true
			local findIdx = idx
			local preIdx = findIdx - 1
			local preValue = 0
			if preIdx >= 1 then
				preValue = calList[preIdx].k
			end
			ret = ret + (value - preValue) * rate
			break
		else
			local preIdx = idx - 1
			local preValue = 0
			if preIdx >= 1 then
				preValue = calList[preIdx].k
			end	
			ret = ret + (info.k - preValue) * rate
		end
	end
	if not tag then
		local final = calList[#calList]
		ret = ret + (value - final.k) * fianl.v
	end
	return ret
end

function makeReportSign(paramTbl, serverTag)
	local key = "sakdhfk19030kakljd10sk"
	local list = {}
	for k, v in pairs(paramTbl) do
		table.insert(list, k)	
	end
	table.sort(list, function(a, b)
		return a<b
	end)
	local tbl = {}
	for _, k in ipairs(list) do
		table.insert(tbl, string.format("%s=%s", k, paramTbl[k]))
	end
	local str = table.concat(tbl, "&") .. "&" .. key
	local sign = ""
	if serverTag then
		sign = COMMON_FUNC.getStrMD5(str)
	else
		sign = fileUtils.getMD5HashFromString(str)
	end
	return sign
end

function sortStr(strTbl)
	local tbl = {}
	local strList = table.values(strTbl)
	for key, str in pairs(strTbl) do
		tbl[str] = key
	end
	CSLuaUtility.sortStrList(strList)
	local sortTbl = strList
	local sortKey = {}
	for idx, str in pairs(sortTbl) do
		sortKey[idx] = tbl[str]
	end
	return sortKey
end

function inStonePolyRange(x, z)
	local plist = {
	}
	--[[
	[1] = {
		x = *,
		z = *,
	},
	2, 3, 4
	clockwise ???
	--]]
	return true
end

function isPointInConvexPolygon(p, polygon)
	if #polygon < 3 then return false end

	local function doCheck(p1, p2)
		return (p[2]-p1[2])*(p2[1]-p1[1])-(p[1]-p1[1])*(p2[2]-p1[2]) > 0
	end

	for i=2,#polygon do
		local p1 = polygon[i-1]
		local p2 = polygon[i]
		if doCheck(p1, p2) then
			return false
		end
	end
	
	if doCheck(polygon[#polygon], polygon[1]) then
		return false
	end

	return true
end

function isMoveBlockLayer(layerType)
	return layerType % 2 == 1
end

function getAttGap(stype, ttype)
	local sdis = COMMON_CONST.ETYPE2RANGE[stype]
	local tdis = COMMON_CONST.ETYPE2RANGE[ttype]
	local gap = sdis + tdis + 100 
	return gap
end

function calDis(src, tar)
	local sx, sz = src:getPosition()
	local tx, tz = tar:getPosition()
	local dx = tx - sx
	local dz = tz - sz
	local dis = math.sqrt(dx * dx + dz * dz)
	return dis
end

