local string = string
local table = table
local pairs = pairs
_G._ImportModule = _G._ImportModule or {}
local _ImportModule = _G._ImportModule
_PathFile = "../../src/"
local function getClassTbl(Module)
	local classTbl = {}
	for k, v in pairs(Module) do
		if type(v) == "table" and v.__IsClass then
			classTbl[k] = v
		end
	end
	return classTbl
end

local function updateImportByContent(pathFile, content)
	return __updateImportByContent(_ImportModule, pathFile, content)
end

local function doImport(PathFile, PathName)
	local New = {}
	setmetatable(New, { __index = _G })
	local file = io.open(_PathFile .. PathFile, "r")
	io.input(file)-- 设置默认输入文件
	local funcString = io.read("*a")
	local func, err = load(funcString, PathName, nil, New)
	io.close()
	
	-- local func, err = loadfile(_PathFile .. PathFile, nil, New) loadfile存在无法读取最新文件问题
	if not func then
		print(string.format("ERROR!!!\n%s\n%s", err, debug.traceback()))
		return func, err
	end
	func()
	_ImportModule[PathFile] = New
	--设置原始环境
	-- local env = _ENV or _G -- lua5.4,setfenv已废除
	if rawget(New, "__init__") then
		New:__init__()
	end

	return New
end

-- 加载器文件hotloader.lua
local function hotloader(moduleName, moduleFile)
    local oldModule = package.loaded[moduleName]
    local newModule
 
    local f = assert(loadfile(moduleFile))
    setfenv(f, oldModule and getfenv(oldModule) or _G)
    newModule = f()
 
    if newModule then
        for k, v in pairs(newModule) do
            oldModule[k] = v
        end
    end
end

local function updateImport(PathFile)
	--doImport(PathFile)
	return __updateImport(_ImportModule, PathFile, loadfile)
end

local function SafeImport(PathFile)
	local Old = _ImportModule[PathFile]
	if Old then
		return Old
	end

	return doImport(PathFile)
end

function Reimport(PathFile)
	local data = doImport(PathFile)
	return data
end

function localEnvDoFile(fileName)
	local env = getfenv(2)
	local func, err = loadfile(_PathFile .. fileName)
	setfenv(func, env)()
end

function Import(PathFile)
	local Module, Err = SafeImport(PathFile)
	assert(Module, Err)

	return Module
end

function updateLuaFile(PathFile)
	local ret = updateImport(PathFile)
	return ret
end

function updateLuaByContent(path, content)
	updateImportByContent(path, content)
end
