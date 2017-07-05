---------------------------------------------------------------------
-- BUFF���
---------------------------------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_BuffMon/lang/")
local INI_PATH = MY.GetAddonInfo().szRoot .. "MY_BuffMon/ui/MY_BuffMon.ini"
local ROLE_CONFIG_FILE = {'config/my_buffmon.jx3dat', MY_DATA_PATH.ROLE}
local DEFAULT_CONFIG_FILE = MY.GetAddonInfo().szRoot .. "MY_BuffMon/data/$lang.jx3dat"
local CUSTOM_BOXBG_STYLES = {
	"UI/Image/Common/Box.UITex|0",
	"UI/Image/Common/Box.UITex|1",
	"UI/Image/Common/Box.UITex|2",
	"UI/Image/Common/Box.UITex|3",
	"UI/Image/Common/Box.UITex|4",
	"UI/Image/Common/Box.UITex|5",
	"UI/Image/Common/Box.UITex|6",
	"UI/Image/Common/Box.UITex|7",
	"UI/Image/Common/Box.UITex|8",
	"UI/Image/Common/Box.UITex|9",
	"UI/Image/Common/Box.UITex|10",
	"UI/Image/Common/Box.UITex|11",
	"UI/Image/Common/Box.UITex|12",
	"UI/Image/Common/Box.UITex|13",
	"UI/Image/Common/Box.UITex|14",
	"UI/Image/Common/Box.UITex|34",
	"UI/Image/Common/Box.UITex|35",
	"UI/Image/Common/Box.UITex|42",
	"UI/Image/Common/Box.UITex|43",
	"UI/Image/Common/Box.UITex|44",
	"UI/Image/Common/Box.UITex|45",
	"UI/Image/Common/Box.UITex|77",
	"UI/Image/Common/Box.UITex|78",
}
local CUSTOM_CDBAR_STYLES = {
	MY.GetAddonInfo().szUITexST .. "|" .. 0,
	MY.GetAddonInfo().szUITexST .. "|" .. 1,
	MY.GetAddonInfo().szUITexST .. "|" .. 2,
	MY.GetAddonInfo().szUITexST .. "|" .. 3,
	MY.GetAddonInfo().szUITexST .. "|" .. 4,
	MY.GetAddonInfo().szUITexST .. "|" .. 5,
	MY.GetAddonInfo().szUITexST .. "|" .. 6,
	MY.GetAddonInfo().szUITexST .. "|" .. 7,
	MY.GetAddonInfo().szUITexST .. "|" .. 8,
	"/ui/Image/Common/Money.UITex|168",
	"/ui/Image/Common/Money.UITex|203",
	"/ui/Image/Common/Money.UITex|204",
	"/ui/Image/Common/Money.UITex|205",
	"/ui/Image/Common/Money.UITex|206",
	"/ui/Image/Common/Money.UITex|207",
	"/ui/Image/Common/Money.UITex|208",
	"/ui/Image/Common/Money.UITex|209",
	"/ui/Image/Common/Money.UITex|210",
	"/ui/Image/Common/Money.UITex|211",
	"/ui/Image/Common/Money.UITex|212",
	"/ui/Image/Common/Money.UITex|213",
	"/ui/Image/Common/Money.UITex|214",
	"/ui/Image/Common/Money.UITex|215",
	"/ui/Image/Common/Money.UITex|216",
	"/ui/Image/Common/Money.UITex|217",
	"/ui/Image/Common/Money.UITex|218",
	"/ui/Image/Common/Money.UITex|219",
	"/ui/Image/Common/Money.UITex|220",
	"/ui/Image/Common/Money.UITex|228",
	"/ui/Image/Common/Money.UITex|232",
	"/ui/Image/Common/Money.UITex|233",
	"/ui/Image/Common/Money.UITex|234",
}
local Config = {}
local BOX_SPARKING_FRAME = GLOBAL.GAME_FPS

----------------------------------------------------------------------------------------------
-- ͨ���߼�
----------------------------------------------------------------------------------------------
local FE = {}
local l_frames = {}
local l_frameIndex = -1
local function ClosePanel(config)
	if not l_frames[config] then
		return
	end
	Wnd.CloseWindow(l_frames[config])
end

local function OpenPanel(config, reload)
	if reload then
		ClosePanel(config)
	end
	if not config.enable then
		return
	end
	local frame = Wnd.OpenWindow(INI_PATH, "MY_BuffMon#" .. l_frameIndex)
	local hList = frame:Lookup("", "Handle_BuffList")
	
	l_frames[config] = frame
	l_frameIndex = l_frameIndex + 1
	
	hList:Clear()
	frame.tItem = {}
	frame.hList = hList
	frame.config = config
	local nWidth = 0
	local nCount = 0
	local function CreateItem(mon)
		if not mon.enable then
			return
		end
		nCount = nCount + 1
		local hItem        = hList:AppendItemFromIni(INI_PATH, "Handle_Item")
		local hBox         = hItem:Lookup("Handle_Box")
		local hCDBar       = hItem:Lookup("Handle_Bar")
		local box          = hBox:Lookup("Box_Default")
		local imgBoxBg     = hBox:Lookup("Image_BoxBg")
		local txtProcess   = hCDBar:Lookup("Text_Process")
		local imgProcess   = hCDBar:Lookup("Image_Process")
		local txtBuffName  = hCDBar:Lookup("Text_Name")
		
		-- ������������
		hItem.box = box
		hItem.mon = mon
		hItem.txtProcess = txtProcess
		hItem.imgProcess = imgProcess
		hItem.txtBuffName = txtBuffName
		if mon.buffid and mon.buffid ~= 'common' then
			if not frame.tItem[mon.buffid] then
				frame.tItem[mon.buffid] = {}
			end
			frame.tItem[mon.buffid][hItem] = true
		elseif mon.buffname then
			if not frame.tItem[mon.buffname] then
				frame.tItem[mon.buffname] = {}
			end
			frame.tItem[mon.buffname][hItem] = true
		end
		
		-- Box����
		box:SetObject(UI_OBJECT.BUFF, mon.buffid, 1, 1)
		box:SetObjectIcon(mon.iconid or 13)
		box:SetObjectCoolDown(true)
		box:SetCoolDownPercentage(0)
		-- BUFFʱ��
		box:SetOverTextPosition(1, ITEM_POSITION.LEFT_TOP)
		box:SetOverTextFontScheme(1, 15)
		-- BUFF����
		box:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
		box:SetOverTextFontScheme(0, 15)
		-- Box����ͼ
		XGUI(imgBoxBg):image(config.boxBgUITex)
		
		-- ����ʱ��
		if config.cdBar then
			txtProcess:SetW(config.cdBarWidth - 10)
			txtProcess:SetText("")
			
			txtBuffName:SetVisible(config.showBuffName)
			txtBuffName:SetW(config.cdBarWidth - 10)
			txtBuffName:SetText(mon.buffname or '')
			
			XGUI(imgProcess):image(config.cdBarUITex)
			imgProcess:SetW(config.cdBarWidth)
			imgProcess:SetPercentage(0)
			
			hCDBar:Show()
			hCDBar:SetW(config.cdBarWidth)
			hItem.hCDBar = hCDBar
			hItem:SetW(hBox:GetW() + config.cdBarWidth)
		else
			hCDBar:Hide()
			hItem:SetW(hBox:GetW())
		end
		
		if nCount <= config.maxLineCount then
			nWidth = nWidth + hItem:GetW() * config.scale
		end
		-- hItem:Scale(config.scale, config.scale)
		hItem:SetVisible(not config.hideVoidBuff)
	end
	for _, mon in ipairs(config.monitors.common or EMPTY_TABLE) do
		CreateItem(mon)
	end
	for _, mon in ipairs(config.monitors[GetClientPlayer().GetKungfuMount().dwSkillID] or EMPTY_TABLE) do
		CreateItem(mon)
	end
	hList:SetW(nWidth)
	hList:FormatAllItemPos()
	hList:SetSizeByAllItemSize()
	hList:SetIgnoreInvisibleChild(true)
	hList:FormatAllItemPos()
	
	local nW, nH = hList:GetSize()
	nW = math.max(nW, 50 * config.scale)
	nH = math.max(nH, 50 * config.scale)
	frame:SetSize(nW, nH)
	frame:SetDragArea(0, 0, nW, nH)
	frame:EnableDrag(config.dragable)
	frame:SetMousePenetrable(not config.dragable)
	frame:Scale(config.scale, config.scale)
	frame:SetPoint(config.anchor.s, 0, 0, config.anchor.r, config.anchor.x, config.anchor.y)
	frame:CorrectPos()
	
	for k, v in pairs(FE) do
		frame[k] = v
	end
	frame:RegisterEvent("SKILL_MOUNT_KUNG_FU")
	frame:RegisterEvent("ON_ENTER_CUSTOM_UI_MODE")
	frame:RegisterEvent("ON_LEAVE_CUSTOM_UI_MODE")
end

local function GetTarget(eType)
	if eType == "CLIENT_PLAYER" then
		return TARGET.PLAYER, UI_GetClientPlayerID()
	elseif eType == "CONTROL_PLAYER" then
		return TARGET.PLAYER, GetControlPlayerID()
	elseif eType == "TARGET" then
		return MY.GetTarget()
	elseif eType == "TTARGET" then
		local KTarget = MY.GetObject(MY.GetTarget())
		if KTarget then
			return MY.GetTarget(KTarget)
		else
			return TARGET.NO_TARGET, 0
		end
	end
end

do
local needFormatItemPos
local l_tBuffTime = setmetatable({}, { __mode = "v" })
local function UpdateItem(hItem, KTarget, buff, szBuffName, tItem, config, nFrameCount, targetChanged)
	if buff then
		if not hItem.mon.buffid or hItem.mon.buffid == 'common' or hItem.mon.buffid == buff.dwID then
			if hItem.nRenderFrame == nFrameCount then
				return
			end
			if config.hideVoidBuff and not hItem:IsVisible() then
				needFormatItemPos = true
				hItem:Show()
			end
			-- ����BUFFʱ��
			local nTimeLeft = ("%.1f"):format(math.max(0, buff.nEndFrame - nFrameCount) / 16)
			local nBuffTime = math.max(GetBuffTime(buff.dwID, buff.nLevel) / 16, nTimeLeft)
			if l_tBuffTime[KTarget.dwID][buff.dwID] then
				nBuffTime = math.max(l_tBuffTime[KTarget.dwID][buff.dwID], nBuffTime)
			end
			l_tBuffTime[KTarget.dwID][buff.dwID] = nBuffTime
			-- �����³��ֵ�BUFF
			if not hItem.mon.iconid or hItem.mon.iconid == 13 then
				-- ����ͼ�� ���� BuffID��
				if hItem.mon.buffid ~= "common" then
					-- ���뾫ȷ����
					if not tItem[buff.dwID] then
						tItem[buff.dwID] = {}
					end
					tItem[buff.dwID][hItem] = true
					-- �Ƴ�ģ������
					if tItem[szBuffName] then
						tItem[szBuffName][hItem] = false
					end
					hItem.mon.buffid = buff.dwID
				end
				if not hItem.mon.buffname then
					hItem.mon.buffname = szBuffName
					hItem.txtBuffName:SetText(szBuffName)
				end
				hItem.mon.iconid = Table_GetBuffIconID(buff.dwID, buff.nLevel) or 13
				hItem.box:SetObjectIcon(hItem.mon.iconid)
			end
			-- ����ʱ �� BUFF�����ѵ�
			hItem.txtProcess:SprintfText("%d'", nTimeLeft)
			hItem.box:SetOverText(1, nTimeLeft .. "'")
			hItem.box:SetOverText(0, buff.nStackNum == 1 and "" or buff.nStackNum)
			-- CD�ٷֱ�
			local fPercent = nTimeLeft / nBuffTime
			hItem.imgProcess:SetPercentage(fPercent)
			hItem.box:SetCoolDownPercentage(fPercent)
			if fPercent < 0.5 and fPercent > 0.3 then
				if hItem.fPercent ~= 0.5 then
					hItem.fPercent = 0.5
					hItem.box:SetObjectStaring(true)
				end
			elseif fPercent < 0.3 and fPercent > 0.1 then
				if hItem.fPercent ~= 0.3 then
					hItem.fPercent = 0.3
					hItem.box:SetExtentAnimate("ui\\Image\\Common\\Box.UITex", 17)
				end
			elseif fPercent < 0.1 then
				if hItem.fPercent ~= 0.1 then
					hItem.fPercent = 0.1
					hItem.box:SetExtentAnimate("ui\\Image\\Common\\Box.UITex", 20)
				end
			else
				hItem.box:SetObjectStaring(false)
				hItem.box:ClearExtentAnimate()
			end
			hItem.nRenderFrame = nFrameCount
		end
		-- ����ͬ��BUFF�б�
		if not hItem.mon.buffids then
			hItem.mon.buffids = {}
		end
		if not hItem.mon.buffids[buff.dwID] then
			hItem.mon.buffids[buff.dwID] = Table_GetBuffIconID(buff.dwID, buff.nLevel) or 13
		end
	else
		hItem.box:SetCoolDownPercentage(0)
		hItem.box:SetObjectStaring(false)
		hItem.box:SetOverText(0, "")
		hItem.box:SetOverText(1, "")
		hItem.box:ClearExtentAnimate()
		hItem.txtProcess:SetText("")
		hItem.imgProcess:SetPercentage(0)
		-- ���Ŀ��û�иı�� �� ֮ǰ���� ����ʾˢ�¶���
		if hItem.nRenderFrame and hItem.nRenderFrame >= 0 and hItem.nRenderFrame ~= nFrameCount and not targetChanged then
			hItem.box:SetObjectSparking(true)
			hItem.nSparkingFrame = nFrameCount
		-- �����ѡ���ز����ڵ�BUFF �� ��ǰδ���� �� (Ŀ��ı�� �� ˢ�¶���û���ڲ���) ������
		elseif config.hideVoidBuff and hItem:IsVisible()
		and (targetChanged or not hItem.nSparkingFrame or nFrameCount - hItem.nSparkingFrame <= BOX_SPARKING_FRAME) then
			hItem:Hide()
			hItem.nSparkingFrame = nil
			needFormatItemPos = true
		end
		hItem.fPercent = 0
		hItem.nRenderFrame = nil
	end
end
function FE.OnFrameBreathe()
	local dwType, dwID = GetTarget(this.config.target)
	if dwType == this.dwType and dwID == this.dwID
	and dwType ~= TARGET.PLAYER and dwType ~= TARGET.NPC then
		return
	end
	needFormatItemPos = false
	local hList = this.hList
	local config = this.config
	local KTarget = MY.GetObject(dwType, dwID)
	local targetChanged = dwType ~= this.dwType or dwID ~= this.dwID
	local nFrameCount = GetLogicFrameCount()
	
	if not KTarget then
		for i = 0, hList:GetItemCount() - 1 do
			UpdateItem(hList:Lookup(i), KTarget, nil, nil, this.tItem, config, nFrameCount, targetChanged)
		end
	else
		-- BUFF���ʱ�仺��
		if not l_tBuffTime[KTarget.dwID] then
			l_tBuffTime[KTarget.dwID] = {}
		end
		-- ���µ�ǰ���ڵ�BUFF�б�
		local dwClientPlayerID  = UI_GetClientPlayerID()
		local dwControlPlayerID = GetControlPlayerID()
		for _, buff in ipairs(MY.GetBuffList(KTarget)) do
			if not config.hideOthers or buff.dwSkillSrcID == dwClientPlayerID or buff.dwSkillSrcID == dwControlPlayerID then
				local szName = Table_GetBuffName(buff.dwID, buff.nLevel) or ""
				local tItems = this.tItem[buff.dwID]
				if tItems then
					for hItem, _ in pairs(tItems) do
						UpdateItem(hItem, KTarget, buff, szName, this.tItem, config, nFrameCount, targetChanged)
					end
				end
				local tItems = this.tItem[szName]
				if tItems then
					for hItem, _ in pairs(tItems) do
						UpdateItem(hItem, KTarget, buff, szName, this.tItem, config, nFrameCount, targetChanged)
					end
				end
			end
		end
		-- ������ʧ��BUFF�б�
		for i = 0, hList:GetItemCount() - 1 do
			if hList:Lookup(i).nRenderFrame ~= nFrameCount then
				UpdateItem(hList:Lookup(i), KTarget, nil, nil, this.tItem, config, nFrameCount, targetChanged)
			end
		end
		-- ��ֹCD������table��GC����
		if targetChanged then
			this.tBuffTime = l_tBuffTime[KTarget.dwID]
		end
		-- ����Ƿ���Ҫ�ػ��������
		if needFormatItemPos then
			hList:FormatAllItemPos()
		end
	end
	this.dwType, this.dwID = dwType, dwID
end
end

function FE.OnFrameDragEnd()
	this:CorrectPos()
	this.config.anchor = GetFrameAnchor(this)
end

function FE.OnEvent(event)
	if event == "SKILL_MOUNT_KUNG_FU" then
		OpenPanel(this.config, true)
	elseif event == "ON_ENTER_CUSTOM_UI_MODE" then
		UpdateCustomModeWindow(this, this.config.caption, not this.config.dragable)
	elseif event == "ON_LEAVE_CUSTOM_UI_MODE" then
		UpdateCustomModeWindow(this, this.config.caption, not this.config.dragable)
		if this.config.dragable then
			this:EnableDrag(true)
		end
		FE.OnFrameDragEnd()
	end
end

----------------------------------------------------------------------------------------------
-- ���ݴ洢
----------------------------------------------------------------------------------------------
do
MY_BuffMonS = {}
RegisterCustomData("MY_BuffMonS.fScale")
RegisterCustomData("MY_BuffMonS.bEnable")
RegisterCustomData("MY_BuffMonS.bDragable")
RegisterCustomData("MY_BuffMonS.bHideOthers")
RegisterCustomData("MY_BuffMonS.nMaxLineCount")
RegisterCustomData("MY_BuffMonS.bHideVoidBuff")
RegisterCustomData("MY_BuffMonS.bCDBar")
RegisterCustomData("MY_BuffMonS.nCDWidth")
RegisterCustomData("MY_BuffMonS.szCDUITex")
RegisterCustomData("MY_BuffMonS.bSkillName")
RegisterCustomData("MY_BuffMonS.anchor")
RegisterCustomData("MY_BuffMonS.tBuffList")
MY_BuffMonT = {}
RegisterCustomData("MY_BuffMonT.fScale")
RegisterCustomData("MY_BuffMonT.bEnable")
RegisterCustomData("MY_BuffMonT.bDragable")
RegisterCustomData("MY_BuffMonT.bHideOthers")
RegisterCustomData("MY_BuffMonT.nMaxLineCount")
RegisterCustomData("MY_BuffMonT.bHideVoidBuff")
RegisterCustomData("MY_BuffMonT.bCDBar")
RegisterCustomData("MY_BuffMonT.nCDWidth")
RegisterCustomData("MY_BuffMonT.szCDUITex")
RegisterCustomData("MY_BuffMonT.bSkillName")
RegisterCustomData("MY_BuffMonT.anchor")
RegisterCustomData("MY_BuffMonT.tBuffList")
local function OnInit()
	local data = MY.LoadLUAData(DEFAULT_CONFIG_FILE)
	Config = MY.LoadLUAData(ROLE_CONFIG_FILE) or data.default
	if MY_BuffMonS.tBuffList then
		if not Config[1] then
			Config[1] = clone(data.template)
		end
		Config[1].caption      = _L['mingyi self buff monitor']
		Config[1].target       = "CLIENT_PLAYER"
		Config[1].scale        = MY_BuffMonS.fScale
		Config[1].enable       = MY_BuffMonS.bEnable
		Config[1].dragable     = MY_BuffMonS.bDragable
		Config[1].hideOthers   = MY_BuffMonS.bHideOthers
		Config[1].maxLineCount = MY_BuffMonS.nMaxLineCount
		Config[1].hideVoidBuff = MY_BuffMonS.bHideVoidBuff
		Config[1].cdBar        = MY_BuffMonS.bCDBar
		Config[1].cdBarWidth   = MY_BuffMonS.nCDWidth
		Config[1].cdBarUITex   = MY_BuffMonS.szCDUITex
		Config[1].showBuffName = MY_BuffMonS.bSkillName
		Config[1].boxBgUITex   = "UI/Image/Common/Box.UITex|44"
		Config[1].anchor       = MY_BuffMonS.anchor
		Config[1].monitors     = {}
		for kungfuid, mons in pairs(MY_BuffMonS.tBuffList) do
			Config[1].monitors[kungfuid] = {}
			for _, mon in ipairs(mons) do
				if mon[4] == -1 then
					mon[4] = 'common'
				end
				if mon[5] and mon[5][-1] then
					mon[5]['common'], mon[5][-1] = mon[5][-1]
				end
				table.insert(Config[1].monitors[kungfuid], {
					enable = mon[1], iconid = mon[2],
					buffname = mon[3], buffid = mon[4], buffids = mon[5]
				})
			end
		end
		MY_BuffMonS.fScale        = nil
		MY_BuffMonS.bEnable       = nil
		MY_BuffMonS.bDragable     = nil
		MY_BuffMonS.bHideOthers   = nil
		MY_BuffMonS.nMaxLineCount = nil
		MY_BuffMonS.bHideVoidBuff = nil
		MY_BuffMonS.bCDBar        = nil
		MY_BuffMonS.nCDWidth      = nil
		MY_BuffMonS.szCDUITex     = nil
		MY_BuffMonS.bSkillName    = nil
		MY_BuffMonS.anchor        = nil
		MY_BuffMonS.tBuffList     = nil
	end
	if MY_BuffMonT.tBuffList then
		if not Config[2] then
			Config[2] = clone(data.template)
		end
		Config[2].caption      = _L['mingyi target buff monitor']
		Config[2].target       = "TARGET"
		Config[2].scale        = MY_BuffMonT.fScale
		Config[2].enable       = MY_BuffMonT.bEnable
		Config[2].dragable     = MY_BuffMonT.bDragable
		Config[2].hideOthers   = MY_BuffMonT.bHideOthers
		Config[2].maxLineCount = MY_BuffMonT.nMaxLineCount
		Config[2].hideVoidBuff = MY_BuffMonT.bHideVoidBuff
		Config[2].cdBar        = MY_BuffMonT.bCDBar
		Config[2].cdBarWidth   = MY_BuffMonT.nCDWidth
		Config[2].cdBarUITex   = MY_BuffMonT.szCDUITex
		Config[2].showBuffName = MY_BuffMonT.bSkillName
		Config[2].boxBgUITex   = "UI/Image/Common/Box.UITex|44"
		Config[2].anchor       = MY_BuffMonT.anchor
		Config[2].monitors     = {}
		for kungfuid, mons in pairs(MY_BuffMonT.tBuffList) do
			Config[2].monitors[kungfuid] = {}
			for _, mon in ipairs(mons) do
				if mon[4] == -1 then
					mon[4] = 'common'
				end
				if mon[5] and mon[5][-1] then
					mon[5]['common'], mon[5][-1] = mon[5][-1]
				end
				table.insert(Config[2].monitors[kungfuid], {
					enable = mon[1], iconid = mon[2],
					buffname = mon[3], buffid = mon[4], buffids = mon[5]
				})
			end
		end
	end
	MY_BuffMonT.fScale        = nil
	MY_BuffMonT.bEnable       = nil
	MY_BuffMonT.bDragable     = nil
	MY_BuffMonT.bHideOthers   = nil
	MY_BuffMonT.nMaxLineCount = nil
	MY_BuffMonT.bHideVoidBuff = nil
	MY_BuffMonT.bCDBar        = nil
	MY_BuffMonT.nCDWidth      = nil
	MY_BuffMonT.szCDUITex     = nil
	MY_BuffMonT.bSkillName    = nil
	MY_BuffMonT.anchor        = nil
	MY_BuffMonT.tBuffList     = nil
	-- ���ؽ���
	for i, config in ipairs(Config) do
		OpenPanel(config, true)
	end
	ConfigTemplate = data.template
end
MY.RegisterInit("MY_BuffMon", OnInit)

local function OnExit()
	MY.SaveLUAData(ROLE_CONFIG_FILE, Config)
end
MY.RegisterExit("MY_BuffMon", OnExit)
end

----------------------------------------------------------------------------------------------
-- ���ý���
----------------------------------------------------------------------------------------------
local PS = {}
local function GenePS(ui, config, x, y, w, h)
	ui:append("WndEditBox", {
		x = x, y = y, w = w * 2 / 3, h = 22,
		r = 255, g = 255, b = 0, text = config.caption,
		onchange = function(raw, val) config.caption = val end,
	})
	ui:append("WndButton2", {
		x = w - 130, y = y,
		w = 60, h = 30,
		text = _L["Export"],
		onclick = function()
			XGUI.OpenTextEditor(var2str(config))
		end,
	})
	ui:append("WndButton2", {
		x = w - 70, y = y,
		w = 60, h = 30,
		text = _L["Delete"],
		onclick = function()
			for i, c in ipairs_r(Config) do
				if config == c then
					table.remove(Config, i)
				end
			end
			ClosePanel(config)
			MY.SwitchTab("MY_BuffMon", true)
		end,
	})
	y = y + 30
	
	ui:append("WndCheckBox", {
		x = x + 20, y = y,
		text = _L['enable'],
		checked = config.enable,
		oncheck = function(bChecked)
			config.enable = bChecked
			OpenPanel(config, true)
		end,
	})
	
	ui:append("WndCheckBox", {
		x = x + 120, y = y, w = 200,
		text = _L['hide others buff'],
		checked = config.hideOthers,
		oncheck = function(bChecked)
			config.hideOthers = bChecked
			OpenPanel(config, true)
		end,
	})

	ui:append("WndComboBox", {
		x = w - 250, y = y, w = 135,
		text = _L['set buff monitor'],
		menu = function()
			local dwKungFuID = GetClientPlayer().GetKungfuMount().dwSkillID
			local t = {{
				szOption = _L['add'],
				fnAction = function()
					local function Next(kungfuid)
						GetUserInput(_L['please input buff name:'], function(szVal)
							szVal = (string.gsub(szVal, "^%s*(.-)%s*$", "%1"))
							if szVal ~= "" then
								if not config.monitors[kungfuid] then
									config.monitors[kungfuid] = {}
								end
								table.insert(config.monitors[kungfuid], {
									enable = true,
									iconid = 13,
									buffid = tonumber(szVal) or nil,
									buffname = not tonumber(szVal) and szVal or nil,
								})
								OpenPanel(config, true)
							end
						end, function() end, function() end, nil, "" )
					end
					MY.Confirm(_L['Add as common or current kunfu?'], function() Next('common') end,
						function() Next(dwKungFuID) end, _L['as common'], _L['as current kunfu'])
				end,
			}}
			local function InsertMenu(mon, monlist)
				local t1 = {
					szOption = mon.buffname or mon.buffid,
					bCheck = true, bChecked = mon.enable,
					fnAction = function()
						mon.enable = not mon.enable
						OpenPanel(config, true)
					end,
					szIcon = "ui/Image/UICommon/CommonPanel2.UITex",
					nFrame = 49,
					nMouseOverFrame = 51,
					nIconWidth = 17,
					nIconHeight = 17,
					szLayer = "ICON_RIGHTMOST",
					fnClickIcon = function()
						for i, m in ipairs_r(monlist) do
							if m == mon then
								table.remove(monlist, i)
							end
						end
						Wnd.CloseWindow("PopupMenuPanel")
						OpenPanel(config, true)
					end,
					nMiniWidth = 120,
				}
				table.insert(t1, {
					szOption = _L['rename'],
					fnAction = function()
						GetUserInput(_L['please input buff name:'], function(szVal)
							szVal = (string.gsub(szVal, "^%s*(.-)%s*$", "%1"))
							if szVal ~= "" then
								mon.buffname = szVal
								OpenPanel(config, true)
							end
						end, function() end, function() end, nil, mon.buffname)
					end,
				})
				if mon.buffids then
					table.insert(t1, { bDevide = true })
					local function InsertMenuBuff(dwBuffID, dwIcon)
						table.insert(t1, {
							szOption = dwBuffID == "common" and _L['all buffid'] or dwBuffID,
							bCheck = true, bMCheck = true,
							bChecked = dwBuffID == mon.buffid or (dwBuffID == "common" and mon.buffid == nil),
							fnAction = function()
								mon.iconid = dwIcon
								mon.buffid = dwBuffID
								OpenPanel(config, true)
							end,
							szIcon = "fromiconid",
							nFrame = dwIcon or 13,
							nIconWidth = 22,
							nIconHeight = 22,
							szLayer = "ICON_RIGHTMOST",
							fnClickIcon = function()
								XGUI.OpenIconPanel(function(dwIcon)
									mon.buffids[dwBuffID] = dwIcon
									if mon.buffid == dwBuffID then
										mon.iconid = dwIcon
										OpenPanel(config, true)
									end
								end)
								Wnd.CloseWindow("PopupMenuPanel")
							end,
						})
					end
					InsertMenuBuff('common', mon.buffids.common or mon.iconid or 13)
					for dwBuffID, dwIcon in pairs(mon.buffids) do
						if dwBuffID ~= "common" then
							InsertMenuBuff(dwBuffID, dwIcon)
						end
					end
				end
				table.insert(t, t1)
			end
			local tBuffMonList = config.monitors.common
			if tBuffMonList and #tBuffMonList > 0 then
				table.insert(t, { bDevide = true })
				for i, mon in ipairs(tBuffMonList) do
					InsertMenu(mon, tBuffMonList)
				end
			end
			local tBuffMonList = config.monitors[GetClientPlayer().GetKungfuMount().dwSkillID]
			if tBuffMonList and #tBuffMonList > 0 then
				table.insert(t, { bDevide = true })
				for i, mon in ipairs(tBuffMonList) do
					InsertMenu(mon, tBuffMonList)
				end
			end
			return t
		end,
	})
	ui:append("WndComboBox", {
		x = w - 115, y = y, w = 105,
		text = _L['set target'],
		menu = function()
			local dwKungFuID = GetClientPlayer().GetKungfuMount().dwSkillID
			local t = {}
			for eType, szText in pairs(_L.TARGET) do
				table.insert(t, {
					szOption = szText,
					rgb = eType == config.target and {255, 255, 0} or nil,
					fnAction = function()
						config.target = eType
						OpenPanel(config, true)
					end,
				})
			end
			return t
		end,
	})
	y = y + 30
	
	ui:append("WndCheckBox", {
		x = x + 20, y = y, w = 100,
		text = _L['undragable'],
		checked = not config.dragable,
		oncheck = function(bChecked)
			config.dragable = not bChecked
			OpenPanel(config, true)
		end,
	})
	
	ui:append("WndCheckBox", {
		x = x + 120, y = y, w = 200,
		text = _L['hide void buff'],
		checked = config.hideVoidBuff,
		oncheck = function(bChecked)
			config.hideVoidBuff = bChecked
			OpenPanel(config, true)
		end,
	})
	
	ui:append("WndSliderBox", {
		x = w - 250, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {1, 32},
		value = config.maxLineCount,
		textfmt = function(val) return _L("display %d eachline.", val) end,
		onchange = function(raw, val)
			config.maxLineCount = val
			OpenPanel(config, true)
		end,
	})
	y = y + 30
	
	ui:append("WndCheckBox", {
		x = x + 20, y = y, w = 120,
		text = _L['show cd bar'],
		checked = config.cdBar,
		oncheck = function(bCheck)
			config.cdBar = bCheck
			OpenPanel(config, true)
		end,
	})
	
	ui:append("WndCheckBox", {
		x = x + 120, y = y, w = 120,
		text = _L['show buff name'],
		checked = config.showBuffName,
		oncheck = function(bCheck)
			config.showBuffName = bCheck
			OpenPanel(config, true)
		end,
	})
	
	ui:append("WndSliderBox", {
		x = w - 250, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {1, 300},
		value = config.scale * 100,
		textfmt = function(val) return _L("scale %d%%.", val) end,
		onchange = function(raw, val)
			config.scale = val / 100
			OpenPanel(config, true)
		end,
	})
	y = y + 30
	
	ui:append("WndComboBox", {
		x = 40, y = y, w = (w - 250 - 30 - 30 - 10) / 2,
		text = _L['Select background style'],
		menu = function()
			local t, subt, szIcon, nFrame = {}
			for _, text in ipairs(CUSTOM_BOXBG_STYLES) do
				szIcon, nFrame = unpack(text:split("|"))
				subt = {
					szOption = text,
					fnAction = function()
						config.boxBgUITex = text
						OpenPanel(config, true)
					end,
					szIcon = szIcon,
					nFrame = nFrame,
					nIconMarginLeft = -3,
					nIconMarginRight = -3,
					szLayer = "ICON_RIGHTMOST",
				}
				if text == config.boxBgUITex then
					subt.rgb = {255, 255, 0}
				end
				table.insert(t, subt)
			end
			return t
		end,
	})
	ui:append("WndComboBox", {
		x = 40 + (w - 250 - 30 - 30 - 10) / 2 + 10, y = y, w = (w - 250 - 30 - 30 - 10) / 2,
		text = _L['Select countdown style'],
		menu = function()
			local t, subt, szIcon, nFrame = {}
			for _, text in ipairs(CUSTOM_CDBAR_STYLES) do
				szIcon, nFrame = unpack(text:split("|"))
				subt = {
					szOption = text,
					fnAction = function()
						config.cdBarUITex = text
						OpenPanel(config, true)
					end,
					szIcon = szIcon,
					nFrame = nFrame,
					szLayer = "ICON_FILL",
				}
				if text == config.cdBarUITex then
					subt.rgb = {255, 255, 0}
				end
				table.insert(t, subt)
			end
			return t
		end,
	})
	
	ui:append("WndSliderBox", {
		x = w - 250, y = y,
		sliderstyle = MY.Const.UI.Slider.SHOW_VALUE,
		range = {50, 1000},
		value = config.cdBarWidth,
		textfmt = function(val) return _L("CD width %dpx.", val) end,
		onchange = function(raw, val)
			config.cdBarWidth = val
			OpenPanel(config, true)
		end,
	})
	y = y + 30
	
	return x, y
end

function PS.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local x, y = 20, 30
	
	for _, config in ipairs(Config) do
		x, y = GenePS(ui, config, x, y, w, h)
		y = y + 20
	end
	y = y + 10
	
	ui:append("WndButton2", {
		x = (w - 290) / 2, y = y,
		w = 60, h = 30,
		text = _L["Create"],
		onclick = function()
			local config = clone(ConfigTemplate)
			table.insert(Config, config)
			OpenPanel(config)
			MY.SwitchTab("MY_BuffMon", true)
		end,
	})
	ui:append("WndButton2", {
		x = (w - 290) / 2 + 70, y = y,
		w = 60, h = 30,
		text = _L["Import"],
		onclick = function()
			GetUserInput(_L['please input import data:'], function(szVal)
				local config = str2var(szVal)
				if config then
					config = MY.FormatDataStructure(config, ConfigTemplate, 1)
					table.insert(Config, config)
					OpenPanel(config)
					MY.SwitchTab("MY_BuffMon", true)
				end
			end, function() end, function() end, nil, "" )
		end,
	})
	ui:append("WndButton2", {
		x = (w - 290) / 2 + 140, y = y,
		w = 80, h = 30,
		text = _L["Reset Default"],
		onclick = function()
			MY.Confirm(_L['Sure to reset default?'], function()
				Config = MY.LoadLUAData(DEFAULT_CONFIG_FILE).default
				for i, config in ipairs(Config) do
					OpenPanel(config, true)
				end
				MY.SwitchTab("MY_BuffMon", true)
			end)
		end,
	})
	y = y + 30
end
MY.RegisterPanel("MY_BuffMon", _L["buff monitor"], _L['Target'], "ui/Image/ChannelsPanel/NewChannels.UITex|141", { 255, 255, 0, 200 }, PS)
