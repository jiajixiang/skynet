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

local function getImportFile(PathFile)
	local file = io.open(_PathFile .. PathFile, "r")
	io.input(file)-- 设置默认输入文件
	local funcString = io.read("*a")
	io.close()
	return funcString
end

local function updateImportByContent(pathFile, content)
	return __updateImportByContent(_ImportModule, pathFile, content)
end

local function doImport(PathFile, Env)
	if not Env then
		Env = {}
		setmetatable(Env, { __index = _G })
		_ImportModule[PathFile] = Env
	end
	local funcString = getImportFile(PathFile)
	local func, err = load(funcString, nil, nil, Env)
	-- local func, err = loadfile(_PathFile .. PathFile, nil, New) loadfile存在无法读取最新文件问题
	if not func then
		print(string.format("ERROR!!!\n%s\n%s", err, debug.traceback()))
		return func, err
	end
	func()
	--设置原始环境
	-- local env = _ENV or _G -- lua5.4,setfenv已废除
	if rawget(Env, "__init__") then
		Env:__init__()
	end

	return Env
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
	return __updateImport(_ImportModule, PathFile)
end

local function SafeImport(PathFile)
	local Old = _ImportModule[PathFile]
	if Old then
		return Old
	end

	return doImport(PathFile)
end

function Reimport(PathFile, Env)
	doImport(PathFile, Env)
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
	return updateImport(PathFile)
end

function updateLuaByContent(path, content)
	updateImportByContent(path, content)
end
