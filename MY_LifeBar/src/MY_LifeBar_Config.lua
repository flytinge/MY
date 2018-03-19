---------------------------------------------------
-- @Author: Emine Zhai (root@derzh.com)
-- @Date:   2018-03-19 11:00:29
-- @Last Modified by:   Emine Zhai (root@derzh.com)
-- @Last Modified time: 2018-03-19 17:17:06
---------------------------------------------------
-----------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local floor, min, max, ceil = math.floor, math.min, math.max, math.ceil
local huge, pi, sin, cos, tan = math.huge, math.pi, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientPlayer, GetPlayer, GetNpc = GetClientPlayer, GetPlayer, GetNpc
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local IsNil, IsNumber, IsFunction = MY.IsNil, MY.IsNumber, MY.IsFunction
local IsBoolean, IsString, IsTable = MY.IsBoolean, MY.IsString, MY.IsTable
-----------------------------------------------------------------------------------------
local _L, D = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_LifeBar/lang/"), {}
local Config_Default = MY.LoadLUAData(MY.GetAddonInfo().szRoot .. "MY_LifeBar/config/$lang.jx3dat")
if not Config_Default then
    return MY.Debug({_L["Default config cannot be loaded, please reinstall!!!"]}, _L["x lifebar"], MY_DEBUG.ERROR)
end
local Config, ConfigLoaded = clone(Config_Default), false
local CONFIG_PATH = "config/xlifebar/%s.jx3dat"

function D.GetConfigPath()
	return (CONFIG_PATH:format(MY_LifeBar.szConfig))
end

function D.LoadConfig(szConfig)
	if szConfig and MY_LifeBar.szConfig ~= szConfig then
		D.SaveConfig()
		MY_LifeBar.szConfig = szConfig
	end
	Config = MY.LoadLUAData({ D.GetConfigPath(), MY_DATA_PATH.GLOBAL })
	Config = MY.FormatDataStructure(Config, Config_Default, true)
	ConfigLoaded = true
	FireUIEvent("MY_LIFEBAR_CONFIG_LOADED")
end
MY.RegisterInit(D.LoadConfig)

function D.SaveConfig()
	if not ConfigLoaded then
		return
	end
	MY.SaveLUAData({ D.GetConfigPath(), MY_DATA_PATH.GLOBAL }, Config)
end
MY.RegisterExit(D.SaveConfig)

MY_LifeBar_Config = setmetatable({}, {
	__call = function(t, op, ...)
		local argc = select("#", ...)
		local argv = {...}
		if op == "get" then
			local config = Config
			for i = 1, argc do
				if not IsTable(config) then
					return
				end
				config = config[argv[i]]
			end
			return config
		elseif op == "set" then
			local config = Config
			for i = 1, argc - 2 do
				if not IsTable(config) then
					return
				end
				config = config[argv[i]]
			end
			if not IsTable(config) then
				return
			end
			config[argv[argc - 1]] = argv[argc]
		elseif op == "reset" then
			Config = clone(Config_Default)
		elseif op == "save" then
			return D.SaveConfig(...)
		elseif op == "load" then
			return D.LoadConfig(...)
		end
	end,
	__index = function(t, k) return Config[k] end,
	__newindex = function(t, k, v) Config[k] = v end,
})
