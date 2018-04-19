---------------------------------------------------
-- @Author: Emine Zhai (root@derzh.com)
-- @Date:   2018-03-19 10:36:40
-- @Last Modified by:   Emine Zhai (root@derzh.com)
-- @Last Modified time: 2018-03-30 15:59:21
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
local Config = MY_LifeBar_Config
if not Config then
    return
end

local D = {
	Reset = MY_LifeBar.Reset,
	Repaint = MY_LifeBar.Repaint,
	IsEnabled = MY_LifeBar.IsEnabled,
	IsShielded = MY_LifeBar.IsShielded,
}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_LifeBar/lang/")

local PS = {}
local function LoadUI(ui)
	ui:children("#WndSliderBox_LifeBarWidth"):value(Config.nLifeWidth)
	ui:children("#WndSliderBox_LifeBarHeight"):value(Config.nLifeHeight)
	ui:children("#WndSliderBox_LifeBarOffsetX"):value(Config.nLifeOffsetX)
	ui:children("#WndSliderBox_LifeBarOffsetY"):value(Config.nLifeOffsetY)
	ui:children("#WndSliderBox_TextOffsetY"):value(Config.nTextOffsetY)
	ui:children("#WndSliderBox_TextLineHeight"):value(Config.nTextLineHeight)
	ui:children("#WndSliderBox_LifePerOffsetX"):value(Config.nLifePerOffsetX)
	ui:children("#WndSliderBox_LifePerOffsetY"):value(Config.nLifePerOffsetY)
	ui:children("#WndSliderBox_Distance"):value(math.sqrt(Config.nDistance) / 64)
	ui:children("#WndSliderBox_Alpha"):value(Config.nAlpha)
	ui:children("#WndCheckBox_ShowSpecialNpc"):check(Config.bShowSpecialNpc)
end
function PS.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()

	local x, y = 10, 15
	local offsety = 45
	-- ����
	ui:append("WndCheckBox", {
		x = x, y = y, text = _L["Enable"],
		checked = MY_LifeBar.bEnabled,
		oncheck = function(bChecked)
			MY_LifeBar.bEnabled = bChecked
			D.Reset(true)
		end,
		tip = function()
			if D.IsShielded() then
				return _L['Can not use in pubg map!']
			end
		end,
		autoenable = function() return not D.IsShielded() end,
	})
	x = x + 80
	-- �����ļ�����
	ui:append("WndEditBox", {
		x = x, y = y, w = 200, h = 25,
		placeholder = _L['Configure name'],
		text = MY_LifeBar.szConfig,
		onblur = function()
			local szConfig = XGUI(this):text():gsub("%s", "")
			if szConfig == "" then
				return
			end
			Config("load", szConfig)
			LoadUI(ui)
			D.Reset()
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	x = x + 235
	ui:append("Text", {
		x = x + 3, y = y - 16,
		text = _L['only enable in those maps below'],
		autoenable = function() return D.IsEnabled() end,
	})
	ui:append("WndCheckBox", {
		x = x, y = y + 9, w = 80, text = _L['arena'],
		checked = Config.bOnlyInArena,
		oncheck = function(bChecked)
			Config.bOnlyInArena = bChecked
			D.Reset(true)
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	x = x + 80
	ui:append("WndCheckBox", {
		x = x, y = y + 9, w = 70, text = _L['battlefield'],
		checked = Config.bOnlyInBattleField,
		oncheck = function(bChecked)
			Config.bOnlyInBattleField = bChecked
			D.Reset(true)
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	x = x + 70
	ui:append("WndCheckBox", {
		x = x, y = y + 9, w = 70, text = _L['dungeon'],
		checked = Config.bOnlyInDungeon,
		oncheck = function(bChecked)
			Config.bOnlyInDungeon = bChecked
			D.Reset(true)
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety
	-- <hr />
	ui:append("Image", "Image_Spliter"):find('#Image_Spliter'):pos(10, y-7):size(w - 20, 2):image('UI/Image/UICommon/ScienceTreeNode.UITex',62)

	x, y = 15, 70
	offsety = 32
	ui:append("WndSliderBox", {
		name = "WndSliderBox_LifeBarWidth",
		x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 5, 150 },
		text = function(value) return _L("lifebar width: %s px.", value) end, -- Ѫ�����
		value = Config.nLifeWidth,
		onchange = function(value)
			Config.nLifeWidth = value
			D.Reset()
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append("WndSliderBox", {
		name = "WndSliderBox_LifeBarHeight",
		x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 5, 150 },
		text = function(value) return _L("lifebar height: %s px.", value) end, -- Ѫ���߶�
		value = Config.nLifeHeight,
		onchange = function(value)
			Config.nLifeHeight = value
			D.Reset()
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append("WndSliderBox", {
		name = "WndSliderBox_LifeBarOffsetX",
		x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { -150, 150 },
		text = function(value) return _L("lifebar offset-x: %d px.", value) end, -- Ѫ��ˮƽƫ��
		value = Config.nLifeOffsetX,
		onchange = function(value)
			Config.nLifeOffsetX = value
			D.Reset()
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append("WndSliderBox", {
		name = "WndSliderBox_LifeBarOffsetY",
		x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 0, 150 },
		text = function(value) return _L("lifebar offset-y: %d px.", value) end, -- Ѫ����ֱƫ��
		value = Config.nLifeOffsetY,
		onchange = function(value)
			Config.nLifeOffsetY = value
			D.Reset()
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append("WndSliderBox", {
		name = "WndSliderBox_LifePerOffsetX",
		x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { -150, 150 },
		text = function(value) return _L("life percentage offset-x: %d px.", value) end, -- Ѫ���ٷֱ�ˮƽƫ��
		value = Config.nLifePerOffsetX,
		onchange = function(value)
			Config.nLifePerOffsetX = value
			D.Reset()
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append("WndSliderBox", {
		name = "WndSliderBox_LifePerOffsetY",
		x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 0, 150 },
		text = function(value) return _L("life percentage offset-y: %d px.", value) end, -- Ѫ���ٷֱ���ֱƫ��
		value = Config.nLifePerOffsetY,
		onchange = function(value)
			Config.nLifePerOffsetY = value
			D.Reset()
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append("WndSliderBox", {
		name = "WndSliderBox_TextOffsetY",
		x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 0, 150 },
		text = function(value) return _L("text offset-y: %d px.", value) end, -- ��һ���ָ߶�
		value = Config.nTextOffsetY,
		onchange = function(value)
			Config.nTextOffsetY = value
			D.Reset()
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append("WndSliderBox", {
		name = "WndSliderBox_TextLineHeight",
		x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 0, 150 },
		text = function(value) return _L("text line height: %d px.", value) end, -- ���и߶�
		value = Config.nTextLineHeight,
		onchange = function(value)
			Config.nTextLineHeight = value
			D.Reset()
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append("WndSliderBox", {
		name = "WndSliderBox_Distance",
		x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_VALUE, range = { 0, 300 },
		text = function(value) return value == 0 and _L["Max Distance: Unlimited."] or _L("Max Distance: %s foot.", value) end,
		value = math.sqrt(Config.nDistance) / 64,
		onchange = function(value)
			Config.nDistance = value * value * 64 * 64
			D.Reset()
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append("WndSliderBox", {
		name = "WndSliderBox_Alpha",
		x = x, y = y, sliderstyle = MY.Const.UI.Slider.SHOW_PERCENT, range = { 0, 255 },
		text = function(value) return _L("alpha: %.0f%%.", value) end, -- ͸����
		value = Config.nAlpha,
		onchange = function(value)
			Config.nAlpha = value * 255 / 100
			D.Reset()
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	-- �Ұ��
	x, y = 350, 75
	offsety = 35
	local function FillColorTable(opt, relation, tartype)
		local cfg = Config.Color[relation]
		opt.rgb = cfg[tartype]
		opt.bColorTable = true
		opt.fnChangeColor = function(_, r, g, b)
			cfg[tartype] = { r, g, b }
			D.Reset()
		end
		if tartype == "Player" then
			table.insert(opt, {
				szOption = _L['Unified force color'],
				bCheck = true, bMCheck = true,
				bChecked = not cfg.DifferentiateForce,
				fnAction = function(_, r, g, b)
					cfg.DifferentiateForce = false
					D.Reset()
				end,
				rgb = cfg[tartype],
				szIcon = 'ui/Image/button/CommonButton_1.UITex',
				nFrame = 69, nMouseOverFrame = 70,
				szLayer = "ICON_RIGHT",
				fnClickIcon = function()
					XGUI.OpenColorPicker(function(r, g, b)
						cfg[tartype] = { r, g, b }
						D.Reset()
					end)
				end,
			})
			table.insert(opt, {
				szOption = _L['Differentiate force color'],
				bCheck = true, bMCheck = true,
				bChecked = cfg.DifferentiateForce,
				fnAction = function(_, r, g, b)
					cfg.DifferentiateForce = true
					D.Reset()
				end,
			})
			table.insert(opt,{ bDevide = true } )
			for dwForceID, szForceTitle in pairs(g_tStrings.tForceTitle) do
				table.insert(opt, {
					szOption = szForceTitle,
					rgb = cfg[dwForceID],
					szIcon = 'ui/Image/button/CommonButton_1.UITex',
					nFrame = 69, nMouseOverFrame = 70,
					szLayer = "ICON_RIGHT",
					fnClickIcon = function()
						XGUI.OpenColorPicker(function(r, g, b)
							cfg[dwForceID] = { r, g, b }
							D.Reset()
						end)
					end,
					fnDisable = function()
						return not cfg.DifferentiateForce
					end,
				})
			end
		end
		return opt
	end
	local function GeneBooleanPopupMenu(cfgs, szPlayerTip, szNpcTip)
		local t = {}
		if szPlayerTip then
			table.insert(t, { szOption = szPlayerTip, bDisable = true } )
			for relation, cfg in pairs(cfgs) do
				if cfg.Player ~= nil then
					table.insert(t, FillColorTable({
						szOption = _L[relation],
						bCheck = true,
						bChecked = cfg.Player,
						fnAction = function()
							cfg.Player = not cfg.Player
							D.Reset()
						end,
					}, relation, "Player"))
				end
			end
		end
		if szPlayerTip and szNpcTip then
			table.insert(t,{ bDevide = true } )
		end
		if szNpcTip then
			table.insert(t,{ szOption = szNpcTip, bDisable = true } )
			for relation, cfg in pairs(cfgs) do
				if cfg.Npc ~= nil then
					table.insert(t, FillColorTable({
						szOption = _L[relation],
						bCheck = true,
						bChecked = cfg.Npc,
						fnAction = function()
							cfg.Npc = not cfg.Npc
							D.Reset()
						end,
					}, relation, "Npc"))
				end
			end
		end
		return t
	end
	-- ��ʾ����
	ui:append("WndComboBox", {
		x = x, y = y, text = _L["name display config"],
		menu = function()
			return GeneBooleanPopupMenu(Config.ShowName, _L["player name display"], _L["npc name display"])
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	-- �ƺ�
	ui:append("WndComboBox", {
		x = x, y = y, text = _L["title display config"],
		menu = function()
			return GeneBooleanPopupMenu(Config.ShowTitle, _L["player title display"], _L["npc title display"])
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	-- ���
	ui:append("WndComboBox", {
		x = x, y = y, text = _L["tong display config"],
		menu = function()
			return GeneBooleanPopupMenu(Config.ShowTong, _L["player tong display"])
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	-- Ѫ������
	ui:append("WndComboBox", {
		x = x, y = y, text = _L["lifebar display config"],
		menu = function()
			local t = GeneBooleanPopupMenu(Config.ShowLife, _L["player lifebar display"], _L["npc lifebar display"])
			table.insert(t, { bDevide = true })
			local t1 = {
				szOption = _L['Draw direction'],
			}
			for _, szDirection in ipairs({ "LEFT_RIGHT", "RIGHT_LEFT", "TOP_BOTTOM", "BOTTOM_TOP" }) do
				table.insert(t1, {
					szOption = _L.DIRECTION[szDirection],
					bCheck = true, bMCheck = true,
					bChecked = Config.szLifeDirection == szDirection,
					fnAction = function()
						Config.szLifeDirection = szDirection
						D.Reset()
					end,
				})
			end
			table.insert(t, t1)
			return t
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	-- ��ʾѪ��%
	ui:append("WndComboBox", {
		x = x, y = y, text = _L["lifepercentage display config"],
		menu = function()
			local t = GeneBooleanPopupMenu(Config.ShowLifePer, _L["player lifepercentage display"], _L["npc lifepercentage display"])
			table.insert(t, { bDevide = true })
			table.insert(t, {
				szOption = _L['hide when unfight'],
				bCheck = true,
				bChecked = Config.bHideLifePercentageWhenFight,
				fnAction = function()
					Config.bHideLifePercentageWhenFight = not Config.bHideLifePercentageWhenFight
					D.Reset()
				end,
			})
			table.insert(t, {
				szOption = _L['hide decimal'],
				bCheck = true,
				bChecked = Config.bHideLifePercentageDecimal,
				fnAction = function()
					Config.bHideLifePercentageDecimal = not Config.bHideLifePercentageDecimal
					D.Reset()
				end,
			})
			return t
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	-- ��ǰ��Ӫ
	ui:append("WndComboBox", {
		x = x, y = y, text = _L["set current camp"],
		menu = function()
			return {{
				szOption = _L['auto detect'],
				bCheck = true, bMCheck = true,
				bChecked = Config.nCamp == -1,
				fnAction = function()
					Config.nCamp = -1
					D.Reset()
				end,
			}, {
				szOption = g_tStrings.STR_CAMP_TITLE[CAMP.GOOD],
				bCheck = true, bMCheck = true,
				bChecked = Config.nCamp == CAMP.GOOD,
				fnAction = function()
					Config.nCamp = CAMP.GOOD
					D.Reset()
				end,
			}, {
				szOption = g_tStrings.STR_CAMP_TITLE[CAMP.EVIL],
				bCheck = true, bMCheck = true,
				bChecked = Config.nCamp == CAMP.EVIL,
				fnAction = function()
					Config.nCamp = CAMP.EVIL
					D.Reset()
				end,
			}, {
				szOption = g_tStrings.STR_CAMP_TITLE[CAMP.NEUTRAL],
				bCheck = true, bMCheck = true,
				bChecked = Config.nCamp == CAMP.NEUTRAL,
				fnAction = function()
					Config.nCamp = CAMP.NEUTRAL
					D.Reset()
				end,
			}}
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety
	offsety = 32

	ui:append("WndCheckBox", {
		x = x, y = y, text = _L['show special npc'],
		checked = Config.bShowSpecialNpc,
		oncheck = function(bChecked)
			Config.bShowSpecialNpc = bChecked
			D.Reset()
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety - 10

	-- ui:append("WndCheckBox", {
	-- 	x = x, y = y, text = _L['adjust index'],
	-- 	checked = Config.bAdjustIndex,
	-- 	oncheck = function(bChecked)
	-- 		Config.bAdjustIndex = bChecked
	-- 		D.Reset()
	-- 	end,
	-- 	autoenable = function() return D.IsEnabled() end,
	-- })
	-- y = y + offsety - 10

	ui:append("WndCheckBox", {
		x = x, y = y, text = _L['show kungfu'],
		checked = Config.bShowKungfu,
		oncheck = function(bChecked)
			Config.bShowKungfu = bChecked
			D.Reset()
		end,
		autoenable = function() return D.IsEnabled() end,
	})

	ui:append("WndCheckBox", {
		x = x + 90, y = y, text = _L['show distance'],
		checked = Config.bShowDistance,
		oncheck = function(bChecked)
			Config.bShowDistance = bChecked
			D.Reset()
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety

	ui:append("WndButton", {
		x = x, y = y, w = 65, text = _L["Font"],
		onclick = function()
			MY.UI.OpenFontPicker(function(nFont)
				Config.nFont = nFont
				D.Reset()
			end)
		end,
		autoenable = function() return D.IsEnabled() end,
	})

	ui:append("WndButton", {
		x = x + 65, y = y, w = 120, text = _L['reset config'],
		onclick = function()
			MessageBox({
				szName = "XLifeBar_Reset",
				szMessage = _L['Are you sure to reset config?'], {
					szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function()
						Config("reset")
						D.Reset()
						LoadUI(ui)
					end
				}, {szOption = g_tStrings.STR_HOTKEY_CANCEL,fnAction = function() end},
			})
		end,
		autoenable = function() return D.IsEnabled() end,
	})
	y = y + offsety
end
MY.RegisterPanel("MY_LifeBar", _L["MY_LifeBar"], _L['General'], "UI/Image/LootPanel/LootPanel.UITex|74", {255,127,0,200}, PS)
