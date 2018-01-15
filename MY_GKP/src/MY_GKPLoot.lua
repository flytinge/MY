-- @Author: Webster
-- @Date:   2016-01-20 09:31:57
-- @Last Modified by:   Administrator
-- @Last Modified time: 2016-12-13 01:08:57
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local insert, remove, concat = table.insert, table.remove, table.concat
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local type, tonumber, tostring = type, tonumber, tostring
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local floor, min, max, ceil = math.floor, math.min, math.max, math.ceil
local pow, sqrt, pi, cos, sin, atan = math.pow, math.sqrt, math.pi, math.cos, math.sin, math.atan
local GetClientPlayer, GetPlayer, GetNpc = GetClientPlayer, GetPlayer, GetNpc
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID

local PATH_ROOT = MY.GetAddonInfo().szRoot .. "MY_GKP/"
local _L = MY.LoadLangPack(PATH_ROOT .. "lang/")

local GKP_LOOT_ANCHOR  = { s = "CENTER", r = "CENTER", x = 0, y = 0 }
local GKP_LOOT_INIFILE = PATH_ROOT .. "ui/MY_GKP_Loot.ini"
local MY_GKP_LOOT_BOSS -- ɢ���ϰ�

local GKP_LOOT_HUANGBABA = {
	[MY.GetItemName(72592)]  = true,
	[MY.GetItemName(68363)]  = true,
	[MY.GetItemName(66190)]  = true,
	[MY.GetItemName(153897)] = true,
}
local GKP_LOOT_AUTO = {}
local GKP_LOOT_AUTO_LIST = { -- ��¼�����ϴε���Ʒ
	-- ����
	[153532] = true,
	[153533] = true,
	[153534] = true,
	[153535] = true,
	-- ����ʯ
	[153190] = true,
	-- ���ʯ
	[150241] = true,
	[150242] = true,
	[150243] = true,
	-- 90
	[72591]  = true,
	[68362]  = true,
	[66189]  = true,
	[4097]   = true,
	[73214]  = true,
	[74368]  = true,
	[153896] = true,
}
local GKP_ITEM_QUALITIES = {
	{ nQuality = -1, szTitle = g_tStrings.STR_ADDON_BLOCK },
	{ nQuality = 1, szTitle = g_tStrings.STR_WHITE },
	{ nQuality = 2, szTitle = g_tStrings.STR_ROLLQUALITY_GREEN },
	{ nQuality = 3, szTitle = g_tStrings.STR_ROLLQUALITY_BLUE },
	{ nQuality = 4, szTitle = g_tStrings.STR_ROLLQUALITY_PURPLE },
	{ nQuality = 5, szTitle = g_tStrings.STR_ROLLQUALITY_NACARAT },
}

local Loot = {}
-- setmetatable(GKP_LOOT_AUTO_LIST, { __index = function() return true end })
MY_GKP_Loot = {
	bVertical = true,
	bSetColor = true,
}
MY.RegisterCustomData("MY_GKP_Loot")

MY_GKP_Loot.tItemConfig = {
	nQualityFilter = -1,
	nAutoPickupQuality = -1,
}
MY.RegisterCustomData("MY_GKP_Loot.tItemConfig")

do
local function onLoadingEnd()
	MY_GKP_Loot.tItemConfig.nQualityFilter = -1
	MY_GKP_Loot.tItemConfig.nAutoPickupQuality = -1
end
MY.RegisterEvent("LOADING_END.MY_GKP_Loot", onLoadingEnd)
end

function MY_GKP_Loot.CanDialog(tar, doodad)
	return doodad.CanDialog(tar)
end

function MY_GKP_Loot.IsItemDisplay(itemData, config)
	return config.nQualityFilter == -1 or itemData.nQuality >= config.nQualityFilter
end

function MY_GKP_Loot.IsItemAutoPickup(itemData, config, doodad, bCanDialog)
	return bCanDialog and config.nAutoPickupQuality ~= -1 and itemData.nQuality >= config.nAutoPickupQuality
end

function MY_GKP_Loot.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("PARTY_LOOT_MODE_CHANGED")
	this:RegisterEvent("PARTY_DISBAND")
	this:RegisterEvent("PARTY_DELETE_MEMBER")
	this:RegisterEvent("DOODAD_LEAVE_SCENE")
	this:RegisterEvent("MY_GKP_LOOT_RELOAD")
	this:RegisterEvent("MY_GKP_LOOT_BOSS")
	local a = GKP_LOOT_ANCHOR
	this:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	this:Lookup("WndContainer_DoodadList"):Clear()
	Loot.AdjustFrame(this)
end

function MY_GKP_Loot.OnFrameBreathe()
	local me = GetClientPlayer()
	local wnd = this:Lookup("WndContainer_DoodadList"):LookupContent(0)
	while wnd do
		local doodad = GetDoodad(wnd.dwDoodadID)
		-- ʰȡ�ж�
		local bCanDialog = MY_GKP_Loot.CanDialog(me, doodad)
		if not MY.IsShieldedVersion() then
			local hList, box = wnd:Lookup("", "Handle_ItemList")
			for i = 0, hList:GetItemCount() - 1 do
				box = hList:Lookup(i):Lookup("Box_Item")
				if MY_GKP_Loot.IsItemAutoPickup(box.itemData, wnd.tItemConfig, doodad, bCanDialog) then
					ExecuteWithThis(box, MY_GKP_Loot.OnItemLButtonClick)
				end
			end
		end
		wnd:Lookup("", "Image_DoodadTitleBg"):SetFrame(bCanDialog and 0 or 3)
		-- Ŀ�����
		local nDistance = 0
		if me and doodad then
			nDistance = floor(sqrt(pow(me.nX - doodad.nX, 2) + pow(me.nY - doodad.nY, 2)) * 10 / 64) / 10
		end
		wnd:Lookup("", "Handle_Compass/Compass_Distance"):SetText(nDistance < 4 and "" or nDistance .. '"')
		-- ��������
		if me then
			wnd:Lookup("", "Handle_Compass/Image_Player"):Show()
			wnd:Lookup("", "Handle_Compass/Image_Player"):SetRotate( - me.nFaceDirection / 128 * pi)
		end
		-- ��Ʒλ��
		local nRotate, nRadius = 0, 10.125
		if me and doodad and nDistance > 0 then
			-- ���нǶ�
			if me.nX == doodad.nX then
				if me.nY > doodad.nY then
					nRotate = pi / 2
				else
					nRotate = - pi / 2
				end
			else
				nRotate = atan((me.nY - doodad.nY) / (me.nX - doodad.nX))
			end
			if nRotate < 0 then
				nRotate = nRotate + pi
			end
			if doodad.nY < me.nY then
				nRotate = pi + nRotate
			end
		end
		local nX = nRadius + nRadius * cos(nRotate) + 2
		local nY = nRadius - 3 - nRadius * sin(nRotate)
		wnd:Lookup("", "Handle_Compass/Image_PointGreen"):SetRelPos(nX, nY)
		wnd:Lookup("", "Handle_Compass"):FormatAllItemPos()
		wnd = wnd:GetNext()
	end
end

function MY_GKP_Loot.OnEvent(szEvent)
	if szEvent == "DOODAD_LEAVE_SCENE" then
		Loot.RemoveLootList(arg0)
	elseif szEvent == "PARTY_LOOT_MODE_CHANGED" then
		if arg1 ~= PARTY_LOOT_MODE.DISTRIBUTE then
			-- Wnd.CloseWindow(this)
		end
	elseif szEvent == "PARTY_DISBAND" or szEvent == "PARTY_DELETE_MEMBER" then
		if szEvent == "PARTY_DELETE_MEMBER" and arg1 ~= UI_GetClientPlayerID() then
			return
		end
		Loot.CloseFrame()
	elseif szEvent == "UI_SCALED" then
		local a = this.anchor or GKP_LOOT_ANCHOR
		this:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	elseif szEvent == "MY_GKP_LOOT_RELOAD" or szEvent == "MY_GKP_LOOT_BOSS" then
		local wnd = this:Lookup("WndContainer_DoodadList"):LookupContent(0)
		local aDoodadID = {}
		while wnd do
			table.insert(aDoodadID, wnd.dwDoodadID)
			wnd = wnd:GetNext()
		end
		for _, dwDoodadID in ipairs(aDoodadID) do
			Loot.DrawLootList(dwDoodadID)
		end
	end
end

function MY_GKP_Loot.OnFrameDragEnd()
	this:CorrectPos()
	local anchor    = GetFrameAnchor(this, "LEFTTOP")
	GKP_LOOT_ANCHOR = anchor
	this.anchor     = anchor
end

function MY_GKP_Loot.OnCheckBoxCheck()
	local name = this:GetName()
	if name == "CheckBox_Mini" then
		Loot.AdjustWnd(this:GetParent())
		Loot.AdjustFrame(this:GetRoot())
	end
end

function MY_GKP_Loot.OnCheckBoxUncheck()
	local name = this:GetName()
	if name == "CheckBox_Mini" then
		Loot.AdjustWnd(this:GetParent())
		Loot.AdjustFrame(this:GetRoot())
	end
end

function MY_GKP_Loot.OnLButtonClick()
	local szName = this:GetName()
	if szName == "Btn_Close" then
		Loot.RemoveLootList(this:GetParent().dwDoodadID)
	elseif szName == "Btn_Style" then
		local wnd = this:GetParent()
		local dwDoodadID = wnd.dwDoodadID
		local menu = {
			{
				szOption = _L["Set Force Color"],
				bCheck = true, bChecked = MY_GKP_Loot.bSetColor,
				fnAction = function()
					MY_GKP_Loot.bSetColor = not MY_GKP_Loot.bSetColor
					FireUIEvent("MY_GKP_LOOT_RELOAD")
				end,
			},
			{ bDevide = true },
			{
				szOption = _L["Link All Item"],
				fnAction = function()
					local szName, aItemData, bSpecial = Loot.GetDoodad(dwDoodadID)
					local t = {}
					for k, v in ipairs(aItemData) do
						table.insert(t, MY_GKP.GetFormatLink(v.item))
					end
					MY.Talk(PLAYER_TALK_CHANNEL.RAID, t)
				end,
			},
			{ bDevide = true },
			{
				szOption = _L["switch styles"],
				fnAction = function()
					MY_GKP_Loot.bVertical = not MY_GKP_Loot.bVertical
					FireUIEvent("MY_GKP_LOOT_RELOAD")
				end,
			},
			{ bDevide = true },
			{
				szOption = _L["About"],
				fnAction = function()
					MY.Alert(_L["GKP_TIPS"])
				end,
			},
		}
		if not MY.IsShieldedVersion() then
			table.insert(menu, MENU_DIVIDER)
			table.insert(menu, Loot.GetQualityFilterMenu())
			table.insert(menu, Loot.GetAutoPickupAllMenu())

			local t = { szOption = _L['Auto pickup this'] }
			for i, p in ipairs(GKP_ITEM_QUALITIES) do
				table.insert(t, {
					szOption = p.szTitle,
					rgb = p.nQuality == -1 and {255, 255, 255} or { GetItemFontColorByQuality(p.nQuality) },
					bCheck = true, bMCheck = true, bChecked = wnd.tItemConfig.nAutoPickupQuality == p.nQuality,
					fnAction = function()
						wnd.tItemConfig.nAutoPickupQuality = p.nQuality
					end,
				})
			end
			table.insert(menu, t)
		end
		PopupMenu(menu)
	elseif szName == "Btn_Boss" then
		Loot.GetBossAction(this:GetParent().dwDoodadID, type(MY_GKP_LOOT_BOSS) == "nil")
	end
end

function MY_GKP_Loot.OnRButtonClick()
	local szName = this:GetName()
	if szName == "Btn_Boss" then
		Loot.GetBossAction(this:GetParent().dwDoodadID, true)
	end
end

function MY_GKP_Loot.OnItemLButtonDown()
	local szName = this:GetName()
	if szName == "Handle_Item" then
		this = this:Lookup("Box_Item")
		this.OnItemLButtonDown()
	end
end

function MY_GKP_Loot.OnItemLButtonUp()
	local szName = this:GetName()
	if szName == "Handle_Item" then
		this = this:Lookup("Box_Item")
		this.OnItemLButtonUp()
	end
end

function MY_GKP_Loot.OnItemMouseEnter()
	local szName = this:GetName()
	if szName == "Handle_Item" or szName == "Box_Item" then
		if szName == "Handle_Item" then
			this = this:Lookup("Box_Item")
			this.OnItemMouseEnter()
		end
		-- local item = this.itemData.item
		-- if itme and item.nGenre == ITEM_GENRE.EQUIPMENT then
		-- 	if itme.nSub == EQUIPMENT_SUB.MELEE_WEAPON then
		-- 		this:SetOverText(3, g_tStrings.WeapenDetail[item.nDetail])
		-- 	else
		-- 		this:SetOverText(3, g_tStrings.tEquipTypeNameTable[item.nSub])
		-- 	end
		-- end
	end
end

function MY_GKP_Loot.OnItemMouseLeave()
	local szName = this:GetName()
	if szName == "Handle_Item" or szName == "Box_Item" then
		if szName == "Handle_Item" then
			this = this:Lookup("Box_Item")
			if this then
				this.OnItemMouseLeave()
			end
		end
		-- if this and this:IsValid() and this.SetOverText then
		-- 	this:SetOverText(3, "")
		-- end
	end
end

-- ����˵�
function MY_GKP_Loot.OnItemLButtonClick()
	local szName = this:GetName()
	if IsCtrlKeyDown() or IsAltKeyDown() then
		return
	end
	if szName == "Handle_Item" or szName == "Box_Item" then
		local box        = szName == "Handle_Item" and this:Lookup("Box_Item") or this
		local data       = box.itemData
		local me, team   = GetClientPlayer(), GetClientTeam()
		local dwDoodadID = data.dwDoodadID
		local doodad     = GetDoodad(dwDoodadID)
		-- if data.bDist or MY_GKP.bDebug then
		if not data.bDist and not data.bBidding then
			if doodad.CanDialog(me) then
				OpenDoodad(me, doodad)
			else
				MY.Topmsg(g_tStrings.TIP_TOO_FAR)
			end
		end
		if data.bDist then
			if not doodad then
				MY.Debug({"Doodad does not exist!"}, "MY_GKP_Loot:OnItemLButtonClick", MY_DEBUG.WARNING)
				return Loot.RemoveLootList(dwDoodadID)
			end
			if not Loot.AuthCheck(dwDoodadID) then
				return
			end
			if IsShiftKeyDown() and GKP_LOOT_AUTO[data.item.nUiId] then
				return Loot.DistributeItem(GKP_LOOT_AUTO[data.item.nUiId], dwDoodadID, data.dwID, data, true)
			else
				return PopupMenu(Loot.GetDistributeMenu(dwDoodadID, data))
			end
		elseif data.bBidding then
			if team.nLootMode ~= PARTY_LOOT_MODE.BIDDING then
				return OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.GOLD_CHANGE_BID_LOOT)
			end
			MY.Sysmsg({_L["GKP does not support bidding, please re open loot list."]})
		elseif data.bNeedRoll then
			MY.Topmsg(g_tStrings.ERROR_LOOT_ROLL)
		else -- �������
			LootItem(dwDoodadID, data.dwID)
		end
	end
end
-- �Ҽ�����
function MY_GKP_Loot.OnItemRButtonClick()
	local szName = this:GetName()
	if szName == "Handle_Item" or szName == "Box_Item" then
		local box  = szName == "Handle_Item" and this:Lookup("Box_Item") or this
		local data = box.itemData
		if not data.bDist then
			return
		end
		local me, team   = GetClientPlayer(), GetClientTeam()
		local dwDoodadID = data.dwDoodadID
		if not Loot.AuthCheck(dwDoodadID) then
			return
		end
		local menu = {}
		table.insert(menu, { szOption = data.szName , bDisable = true })
		table.insert(menu, { bDevide = true })
		table.insert(menu, {
			szOption = "Roll",
			fnAction = function()
				if MY_RollMonitor then
					if MY_RollMonitor.OpenPanel and MY_RollMonitor.Clear then
						MY_RollMonitor.OpenPanel()
						MY_RollMonitor.Clear({echo=false})
					end
				end
				MY.Talk(PLAYER_TALK_CHANNEL.RAID, { MY_GKP.GetFormatLink(data.item), MY_GKP.GetFormatLink(_L["Roll the dice if you wang"]) })
			end
		})
		table.insert(menu, { bDevide = true })
		for k, v in ipairs(MY_GKP.GetConfig().Scheme) do
			if v[2] then
				table.insert(menu, {
					szOption = v[1],
					fnAction = function()
						GKP_Chat.OpenFrame(data.item, Loot.GetDistributeMenu(dwDoodadID, data), {
							dwDoodadID = dwDoodadID,
							data = data,
						})
						MY.Talk(PLAYER_TALK_CHANNEL.RAID, { MY_GKP.GetFormatLink(data.item), MY_GKP.GetFormatLink(_L(" %d Gold Start Bidding, off a price if you want.", v[1])) })
					end
				})
			end
		end
		PopupMenu(menu)
	end
end

function Loot.GetQualityFilterMenu()
	local t = { szOption = _L['Quality filter'] }
	for i, p in ipairs(GKP_ITEM_QUALITIES) do
		table.insert(t, {
			szOption = p.szTitle,
			rgb = p.nQuality == -1 and {255, 255, 255} or { GetItemFontColorByQuality(p.nQuality) },
			bCheck = true, bMCheck = true, bChecked = MY_GKP_Loot.tItemConfig.nQualityFilter == p.nQuality,
			fnAction = function()
				MY_GKP_Loot.tItemConfig.nQualityFilter = p.nQuality
			end,
		})
	end
	return t
end

function Loot.GetAutoPickupAllMenu()
	local t = { szOption = _L['Auto pickup all'] }
	for i, p in ipairs(GKP_ITEM_QUALITIES) do
		table.insert(t, {
			szOption = p.szTitle,
			rgb = p.nQuality == -1 and {255, 255, 255} or { GetItemFontColorByQuality(p.nQuality) },
			bCheck = true, bMCheck = true, bChecked = MY_GKP_Loot.tItemConfig.nAutoPickupQuality == p.nQuality,
			fnAction = function()
				MY_GKP_Loot.tItemConfig.nAutoPickupQuality = p.nQuality
			end,
		})
	end
	return t
end

function Loot.GetBossAction(dwDoodadID, bMenu)
	if not Loot.AuthCheck(dwDoodadID) then
		return
	end
	local szName, aItemData = Loot.GetDoodad(dwDoodadID)
	local fnAction = function()
		local tEquipment = {}
		for k, v in ipairs(aItemData) do
			if (v.item.nGenre == ITEM_GENRE.EQUIPMENT or IsCtrlKeyDown())
				and v.item.nSub ~= EQUIPMENT_SUB.WAIST_EXTEND
				and v.item.nSub ~= EQUIPMENT_SUB.BACK_EXTEND
				and v.item.nSub ~= EQUIPMENT_SUB.HORSE
				and v.item.nSub ~= EQUIPMENT_SUB.PACKAGE
				and v.item.nSub ~= EQUIPMENT_SUB.FACE_EXTEND
				and v.item.nSub ~= EQUIPMENT_SUB.L_SHOULDER_EXTEND
				and v.item.nSub ~= EQUIPMENT_SUB.R_SHOULDER_EXTEND
				and v.item.nSub ~= EQUIPMENT_SUB.BACK_CLOAK_EXTEND
				and v.bDist
			then -- ��סCtrl������� ���ӷ��� ����ֻ��װ��
				table.insert(tEquipment, v.item)
			end
		end
		if #tEquipment == 0 then
			return MY.Alert(_L["No Equiptment left for Equiptment Boss"])
		end
		local aPartyMember = Loot.GetaPartyMember(GetDoodad(dwDoodadID))
		local p = aPartyMember(MY_GKP_LOOT_BOSS)
		if p and p.bOnlineFlag then  -- ����˴����Ŷӵ������
			local szXml = GetFormatText(_L["Are you sure you want the following item\n"], 162, 255, 255, 255)
			local r, g, b = MY.GetForceColor(p.dwForceID)
			for k, v in ipairs(tEquipment) do
				local r, g, b = GetItemFontColorByQuality(v.nQuality)
				szXml = szXml .. GetFormatText("[".. GetItemNameByItem(v) .."]\n", 166, r, g, b)
			end
			szXml = szXml .. GetFormatText(_L["All distrubute to"], 162, 255, 255, 255)
			szXml = szXml .. GetFormatText("[".. p.szName .."]", 162, r, g, b)
			local msg = {
				szMessage = szXml,
				szName = "GKP_Distribute",
				szAlignment = "CENTER",
				bRichText = true,
				{
					szOption = g_tStrings.STR_HOTKEY_SURE,
					fnAction = function()
						for k, v in ipairs(tEquipment) do
							Loot.DistributeItem(MY_GKP_LOOT_BOSS, dwDoodadID, v.dwID, {}, true)
						end
					end
				},
				{
					szOption = g_tStrings.STR_HOTKEY_CANCEL
				},
			}
			MessageBox(msg)
		else
			return MY.Alert(_L["No Pick up Object, may due to Network off - line"])
		end
	end
	if bMenu then
		local menu = MY_GKP.GetTeamMemberMenu(function(v)
			MY_GKP_LOOT_BOSS = v.dwID
			fnAction()
		end, false, true)
		table.insert(menu, 1, { bDevide = true })
		table.insert(menu, 1, { szOption = _L["select equip boss"], bDisable = true })
		PopupMenu(menu)
	else
		fnAction()
	end
end

function Loot.AuthCheck(dwID)
	local me, team       = GetClientPlayer(), GetClientTeam()
	local doodad         = GetDoodad(dwID)
	if not doodad then
		return MY.Debug({"Doodad does not exist!"}, "MY_GKP_Loot:AuthCheck", MY_DEBUG.WARNING)
	end
	local nLootMode      = team.nLootMode
	local dwBelongTeamID = doodad.GetBelongTeamID()
	if nLootMode ~= PARTY_LOOT_MODE.DISTRIBUTE and not MY_GKP.bDebug then -- ��Ҫ������ģʽ
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.GOLD_CHANGE_DISTRIBUTE_LOOT)
		return false
	end
	if not MY.IsDistributer() and not MY_GKP.bDebug then -- ��Ҫ�Լ��Ƿ�����
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ERROR_LOOT_DISTRIBUTE)
		return false
	end
	if dwBelongTeamID ~= team.dwTeamID then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ERROR_LOOT_DISTRIBUTE)
		return false
	end
	return true
end
-- ʰȡ����
function Loot.GetaPartyMember(doodad)
	local team = GetClientTeam()
	local aPartyMember = doodad.GetLooterList()
	if not aPartyMember then
		return MY.Sysmsg({_L["Pick up time limit exceeded, please try again."]})
	end
	for k, v in ipairs(aPartyMember) do
		local player = team.GetMemberInfo(v.dwID)
		aPartyMember[k].dwForceID = player.dwForceID
		aPartyMember[k].dwMapID   = player.dwMapID
	end
	setmetatable(aPartyMember, { __call = function(me, dwID)
		for k, v in ipairs(me) do
			if v.dwID == dwID or v.szName == dwID then
				return v
			end
		end
	end })
	return aPartyMember
end
-- �ϸ��ж�
function Loot.DistributeItem(dwID, dwDoodadID, dwItemID, info, bShift)
	local doodad = GetDoodad(dwDoodadID)
	if not Loot.AuthCheck(dwDoodadID) then
		return
	end
	local me = GetClientPlayer()
	local item = GetItem(dwItemID)
	if not item then
		MY.Debug({"Item does not exist, check!!"}, "MY_GKP_Loot", MY_DEBUG.WARNING)
		local szName, aItemData = Loot.GetDoodad(dwDoodadID)
		for k, v in ipairs(aItemData) do
			if v.nQuality == info.nQuality and GetItemNameByItem(v.item) == info.szName then
				dwItemID = v.item.dwID
				MY.Debug({"Item matching, " .. GetItemNameByItem(v.item)}, "MY_GKP_Loot", MY_DEBUG.LOG)
				break
			end
		end
	end
	local item         = GetItem(dwItemID)
	local team         = GetClientTeam()
	local player       = team.GetMemberInfo(dwID)
	local aPartyMember = Loot.GetaPartyMember(doodad)
	if item then
		if not player or (player and not player.bIsOnLine) then -- ������
			return MY.Alert(_L["No Pick up Object, may due to Network off - line"])
		end
		if not aPartyMember(dwID) then -- ������
			return MY.Alert(_L["No Pick up Object, may due to Network off - line"])
		end
		if player.dwMapID ~= me.GetMapID() then -- ����ͬһ��ͼ
			return MY.Alert(_L["No Pick up Object, Please confirm that in the Dungeon."])
		end
		local tab = {
			szPlayer   = player.szName,
			nUiId      = item.nUiId,
			szNpcName  = doodad.szName,
			dwDoodadID = doodad.dwID,
			dwTabType  = item.dwTabType,
			dwIndex    = item.dwIndex,
			nVersion   = item.nVersion,
			nTime      = GetCurrentTime(),
			nQuality   = item.nQuality,
			dwForceID  = player.dwForceID,
			szName     = GetItemNameByItem(item),
			nGenre     = item.nGenre,
		}
		if item.bCanStack and item.nStackNum > 1 then
			tab.nStackNum = item.nStackNum
		end
		if item.nGenre == ITEM_GENRE.BOOK then
			tab.nBookID = item.nBookID
		end
		if MY_GKP.bOn then
			MY_GKP.Record(tab, item, IsShiftKeyDown() or bShift)
		else -- �رյ�������ж���ȫ���ƹ�
			tab.nMoney = 0
			MY_GKP("GKP_Record", tab)
		end
		if GKP_LOOT_AUTO_LIST[item.nUiId] then
			GKP_LOOT_AUTO[item.nUiId] = dwID
		end
		doodad.DistributeItem(dwItemID, dwID)
	else
		MY.Sysmsg({_L["Userdata is overdue, distribut failed, please try again."]})
	end
end

function Loot.GetMessageBox(dwID, dwDoodadID, dwItemID, data, bShift)
	local team = GetClientTeam()
	local info = team.GetMemberInfo(dwID)
	local fr, fg, fb = MY.GetForceColor(info.dwForceID)
	local ir, ig, ib = GetItemFontColorByQuality(data.nQuality)
	local msg = {
		szMessage = FormatLinkString(
			g_tStrings.PARTY_DISTRIBUTE_ITEM_SURE,
			"font=162",
			GetFormatText("[".. data.szName .. "]", 166, ir, ig, ib),
			GetFormatText("[".. info.szName .. "]", 162, fr, fg, fb)
		),
		szName = "GKP_Distribute",
		bRichText = true,
		{
			szOption = g_tStrings.STR_HOTKEY_SURE,
			fnAction = function()
				Loot.DistributeItem(dwID, dwDoodadID, dwItemID, data, bShift)
			end
		},
		{ szOption = g_tStrings.STR_HOTKEY_CANCEL },
	}
	MessageBox(msg)
end

function Loot.GetDistributeMenu(dwDoodadID, data)
	local me, team     = GetClientPlayer(), GetClientTeam()
	local dwMapID      = me.GetMapID()
	local doodad       = GetDoodad(dwDoodadID)
	local aPartyMember = Loot.GetaPartyMember(doodad)
	table.sort(aPartyMember, function(a, b)
		return a.dwForceID < b.dwForceID
	end)
	local menu = {
		{ szOption = data.szName, bDisable = true },
		{ bDevide = true }
	}
	local fnGetMenu = function(v, szName)
		local frame = Loot.GetFrame()
		local wnd = Loot.GetDoodadWnd(frame, dwDoodadID)
		local szIcon, nFrame = GetForceImage(v.dwForceID)
		return {
			szOption = v.szName .. (szName and " - " .. szName or ""),
			bDisable = not v.bOnlineFlag,
			rgb = { MY.GetForceColor(v.dwForceID) },
			szIcon = szIcon, nFrame = nFrame,
			fnAutoClose = function()
				return not wnd or not wnd:IsValid()
			end,
			szLayer = "ICON_RIGHTMOST",
			fnAction = function()
				if data.nQuality >= 3 then
					Loot.GetMessageBox(v.dwID, dwDoodadID, data.dwID, data, szName and true)
				else
					Loot.DistributeItem(v.dwID, dwDoodadID, data.dwID, data, szName and true)
				end
			end
		}
	end
	if GKP_LOOT_AUTO[data.item.nUiId] then
		local member = aPartyMember(GKP_LOOT_AUTO[data.item.nUiId])
		if member then
			table.insert(menu, fnGetMenu(member, data.szName))
			table.insert(menu, { bDevide = true })
		end
	end
	for k, v in ipairs(aPartyMember) do
		table.insert(menu, fnGetMenu(v))
	end
	return menu
end

function Loot.AdjustFrame(frame)
	local container = frame:Lookup("WndContainer_DoodadList")
	local nW, nH = frame:GetW(), 0
	local wnd = container:LookupContent(0)
	while wnd do
		nW = wnd:GetW()
		nH = nH + wnd:GetH()
		wnd = wnd:GetNext()
	end
	container:FormatAllContentPos()
	container:SetSize(nW, nH)
	frame:SetSize(nW, nH)
end

function Loot.AdjustWnd(wnd)
	local nInnerW = MY_GKP_Loot.bVertical and 270 or (52 * 8)
	local nOuterW = MY_GKP_Loot.bVertical and nInnerW or (nInnerW + 10)
	local hDoodad = wnd:Lookup("", "")
	local hList = hDoodad:Lookup("Handle_ItemList")
	local bMini = wnd:Lookup("CheckBox_Mini"):IsCheckBoxChecked()
	hList:SetW(nInnerW)
	hList:SetRelX((nOuterW - nInnerW) / 2)
	hList:FormatAllItemPos()
	hList:SetSizeByAllItemSize()
	hList:SetVisible(not bMini)
	hDoodad:SetSize(nOuterW, (bMini and 0 or hList:GetH()) + 30)
	hDoodad:Lookup("Handle_Compass"):SetRelX(nOuterW - 107)
	hDoodad:Lookup("Image_DoodadTitleBg"):SetW(nOuterW)
	hDoodad:Lookup("Image_DoodadBg"):SetSize(nOuterW, hDoodad:GetH() - 20)
	hDoodad:FormatAllItemPos()
	wnd:SetSize(nOuterW, hDoodad:GetH())
	wnd:Lookup("Btn_Boss"):SetRelX(nOuterW - 80)
	wnd:Lookup("CheckBox_Mini"):SetRelX(nOuterW - 50)
	wnd:Lookup("Btn_Close"):SetRelX(nOuterW - 28)
end

function Loot.GetDoodadWnd(frame, dwID, bCreate)
	if not frame then
		return
	end
	local container = frame:Lookup("WndContainer_DoodadList")
	local wnd = container:LookupContent(0)
	while wnd and wnd.dwDoodadID ~= dwID do
		wnd = wnd:GetNext()
	end
	if not wnd and bCreate then
		wnd = container:AppendContentFromIni(GKP_LOOT_INIFILE, "Wnd_Doodad")
		wnd.dwDoodadID = dwID
		wnd.tItemConfig = setmetatable({}, { __index = MY_GKP_Loot.tItemConfig })
	end
	return wnd
end

function Loot.DrawLootList(dwID)
	local frame = Loot.GetFrame()
	local wnd = Loot.GetDoodadWnd(frame, dwID)
	local config = wnd and wnd.tItemConfig or MY_GKP_Loot.tItemConfig

	-- �������
	local szName, aItemData, bSpecial = Loot.GetDoodad(dwID)
	local nCount = #aItemData
	if config.nQualityFilter ~= -1 then
		nCount = 0
		for i, v in ipairs(aItemData) do
			if MY_GKP_Loot.IsItemDisplay(v, config) then
				nCount = nCount + 1
			end
		end
	end
	MY.Debug({(string.format("Doodad %d, items %d.", dwID, nCount))}, "MY_GKP_Loot", MY_DEBUG.LOG)

	if not szName or nCount == 0 then
		if frame then
			Loot.RemoveLootList(dwID)
		end
		return MY.Debug({"Doodad does not exist!"}, "MY_GKP_Loot:DrawLootList", MY_DEBUG.LOG)
	end

	-- ��ȡ/����UIԪ��
	if not frame then
		frame = Loot.OpenFrame()
	end
	if not wnd then
		wnd = Loot.GetDoodadWnd(frame, dwID, true)
	end
	config = wnd.tItemConfig

	-- �޸�UIԪ��
	local hDoodad = wnd:Lookup("", "")
	local hList = hDoodad:Lookup("Handle_ItemList")
	hList:Clear()
	for i, itemData in ipairs(aItemData) do
		local item = itemData.item
		if MY_GKP_Loot.IsItemDisplay(itemData, config) then
			local szName = GetItemNameByItem(item)
			local h = hList:AppendItemFromIni(GKP_LOOT_INIFILE, "Handle_Item")
			local box = h:Lookup("Box_Item")
			local txt = h:Lookup("Text_Item")
			txt:SetText(szName)
			txt:SetFontColor(GetItemFontColorByQuality(item.nQuality))
			if MY_GKP_Loot.bSetColor and item.nGenre == ITEM_GENRE.MATERIAL then
				for dwForceID, szForceTitle in pairs(g_tStrings.tForceTitle) do
					if szName:find(szForceTitle) then
						txt:SetFontColor(MY.GetForceColor(dwForceID))
						break
					end
				end
			end
			if MY_GKP_Loot.bVertical then
				h:Lookup("Image_Spliter"):SetVisible(i ~= #aItemData)
			else
				txt:Hide()
				box:SetSize(48, 48)
				box:SetRelPos(2, 2)
				h:SetSize(52, 52)
				h:FormatAllItemPos()
				h:Lookup("Image_Spliter"):Hide()
				h:Lookup("Image_Hover"):SetSize(0, 0)
			end
			UpdateBoxObject(box, UI_OBJECT_ITEM_ONLY_ID, item.dwID)
			-- box:SetOverText(3, "")
			-- box:SetOverTextFontScheme(3, 15)
			-- box:SetOverTextPosition(3, ITEM_POSITION.LEFT_TOP)
			if GKP_LOOT_AUTO[item.nUiId] then
				box:SetObjectStaring(true)
			end
			box.itemData = itemData
		end
	end
	if bSpecial then
		hDoodad:Lookup("Image_DoodadBg"):FromUITex("ui/Image/OperationActivity/RedEnvelope2.uitex", 14)
		hDoodad:Lookup("Image_DoodadTitleBg"):FromUITex("ui/Image/OperationActivity/RedEnvelope2.uitex", 14)
		hDoodad:Lookup("Text_Title"):SetAlpha(255)
		hDoodad:Lookup("SFX"):Show()
	end
	hDoodad:Lookup("Text_Title"):SetText(szName .. " (" .. #aItemData ..  ")")

	-- �޸�UI��С
	Loot.AdjustWnd(wnd)
	Loot.AdjustFrame(frame)
end

function Loot.RemoveLootList(dwID)
	local frame = Loot.GetFrame()
	if not frame then
		return
	end
	local container = frame:Lookup("WndContainer_DoodadList")
	local wnd = container:LookupContent(0)
	while wnd and wnd.dwDoodadID ~= dwID do
		wnd = wnd:GetNext()
	end
	if wnd then
		wnd:Destroy()
		Loot.AdjustFrame(frame)
	end
	if container:GetAllContentCount() == 0 then
		return Loot.CloseFrame()
	end
end

function Loot.GetFrame()
	return Station.Lookup("Normal/MY_GKP_Loot")
end

function Loot.OpenFrame()
	local frame = Loot.GetFrame()
	if not frame then
		frame = Wnd.OpenWindow(GKP_LOOT_INIFILE, "MY_GKP_Loot")
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
	end
	return frame
end

-- �ֶ��ر� �������Զ��ر�
function Loot.CloseFrame(dwID)
	local frame = Loot.GetFrame(dwID)
	if frame then
		Wnd.CloseWindow(frame)
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
end

-- �����Ʒ
function Loot.GetDoodad(dwID)
	local me   = GetClientPlayer()
	local d    = GetDoodad(dwID)
	local aItemData = {}
	local szName
	local bSpecial = false
	if me and d then
		szName = d.szName
		local nLootItemCount = d.GetItemListCount()
		for i = 0, nLootItemCount - 1 do
			local item, bNeedRoll, bDist, bBidding = d.GetLootItem(i, me)
			if item and item.nQuality > 0 then
				local szItemName = GetItemNameByItem(item)
				if GKP_LOOT_HUANGBABA[szItemName] then
					bSpecial = true
				end
				-- bSpecial = true -- debug
				table.insert(aItemData, {
					dwDoodadID   = dwID         ,
					szDoodadName = szName       ,
					item         = item         ,
					szName       = szItemName   ,
					dwID         = item.dwID    ,
					nGenre       = item.nGenre  ,
					nQuality     = item.nQuality,
					bNeedRoll    = bNeedRoll    ,
					bDist        = bDist        ,
					bBidding     = bBidding     ,
				})
			end
		end
	end
	return szName, aItemData, bSpecial
end

-- ������
MY.RegisterEvent("OPEN_DOODAD", function()
	if not MY_GKP.bOn then
		return
	end
	if arg1 == UI_GetClientPlayerID() then
		local team = GetClientTeam()
		if not team or team
			and team.nLootMode ~= PARTY_LOOT_MODE.DISTRIBUTE
			-- and not (MY_GKP.bDebug2 and MY_GKP.bDebug)
		then
			return
		end
		local doodad = GetDoodad(arg0)
		local nM = doodad.GetLootMoney() or 0
		if nM > 0 then
			LootMoney(arg0)
			PlaySound(SOUND.UI_SOUND, g_sound.PickupMoney)
		end
		local szName, data = Loot.GetDoodad(arg0)
		if #data == 0 then
			return Loot.RemoveLootList(arg0)
		end
		Loot.DrawLootList(arg0)
		MY.Debug({"Open Doodad: " .. arg0}, "MY_GKP_Loot", MY_DEBUG.LOG)
		local hLoot = Station.Lookup("Normal/LootList")
		if hLoot then
			hLoot:SetAbsPos(4096, 4096)
		end
		-- Wnd.CloseWindow("LootList")
	end
end)

-- ˢ������
MY.RegisterEvent("SYNC_LOOT_LIST", function()
	if not MY_GKP.bOn then
		return
	end
	local frame = Loot.GetFrame()
	local wnd = Loot.GetDoodadWnd(frame, arg0)
	if not wnd and not (MY_GKP.bDebug and MY_GKP.bDebug2) then
		return
	end
	Loot.DrawLootList(arg0)
end)

MY.RegisterEvent("MY_GKP_LOOT_BOSS", function()
	if not arg0 then
		MY_GKP_LOOT_BOSS = nil
		GKP_LOOT_AUTO = {}
	else
		local team = GetClientTeam()
		if team then
			for k, v in ipairs(team.GetTeamMemberList()) do
				local info = GetClientTeam().GetMemberInfo(v)
				if info.szName == arg0 then
					MY_GKP_LOOT_BOSS = v
					break
				end
			end
		end
	end
end)

local ui = {
	GetMessageBox        = Loot.GetMessageBox,
	GetaPartyMember      = Loot.GetaPartyMember,
	GetQualityFilterMenu = Loot.GetQualityFilterMenu,
	GetAutoPickupAllMenu = Loot.GetAutoPickupAllMenu,
}
setmetatable(MY_GKP_Loot, { __index = ui, __newindex = function() end, __metatable = true })
