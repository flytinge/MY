--------------------------------------------
-- @Desc  : �����б�
-- @Author: ���� @ ˫���� @ ݶ����
-- @Date  : 2014-07-30 19:22:10
-- @Email : admin@derzh.com
-- @Last modified by:   tinymins
-- @Last modified time: 2017-05-27 10:59:42
--------------------------------------------
-----------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local huge, pi = math.huge, math.pi
local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil
local pow, sqrt, sin, cos, tan = math.pow, math.sqrt, math.sin, math.cos, math.tan
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
local INI_PATH = MY.GetAddonInfo().szRoot .. 'MY_Focus/ui/MY_Focus.ini'
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_Focus/lang/")
local l_dwLockType, l_dwLockID, l_lockInDisplay
local D = {}

function D.Scale(frame)
	if frame.fScaleX and frame.fScaleY then
		frame:Scale(1 / frame.fScaleX, 1 / frame.fScaleY)
	end
	frame.fScaleX = MY_Focus.fScaleX
	frame.fScaleY = MY_Focus.fScaleY
	frame:Scale(MY_Focus.fScaleX, MY_Focus.fScaleY)
	XGUI(frame):find(".Text"):fontScale((MY_Focus.fScaleX + MY_Focus.fScaleY) / 2)
end

function D.CreateList(frame)
	local hList = frame:Lookup('', 'Handle_List')
	hList:Clear()
	for i = 1, MY_Focus.nMaxDisplay do
		local hItem = hList:AppendItemFromIni(INI_PATH, 'Handle_Info')
		if frame.fScaleX and frame.fScaleY then
			hItem:Scale(frame.fScaleX, frame.fScaleY)
			XGUI(hItem):find(".Text"):fontScale((frame.fScaleX + frame.fScaleY) / 2)
		end
		hItem:Hide()
	end
	hList:FormatAllItemPos()
end

function MY_Focus.Open()
	Wnd.OpenWindow(INI_PATH, 'MY_Focus')
end

function MY_Focus.Close()
	local hFrame = MY_Focus.GetFrame()
	if hFrame then
		Wnd.CloseWindow(hFrame)
	end
end

function MY_Focus.GetFrame(szWnd, szItem)
	if szWnd then
		if szItem then
			return Station.Lookup('Normal/MY_Focus/' .. szWnd, szItem)
		else
			return Station.Lookup('Normal/MY_Focus/' .. szWnd)
		end
	else
		return Station.Lookup('Normal/MY_Focus')
	end
end

-- ��ȡָ�������Handle û�з���nil
function MY_Focus.GetHandle(dwType, dwID)
	return Station.Lookup('Normal/MY_Focus', 'Handle_List/HI_'..dwType..'_'..dwID)
end

-- ����Ӧ���������С
function D.AutosizeUI(frame)
	local nHeight = 0
	local hList = frame:Lookup('', 'Handle_List')
	for i = 0, hList:GetItemCount() - 1 do
		local hItem = hList:Lookup(i)
		if hItem:IsVisible() then
			nHeight = nHeight + hItem:GetH()
		end
	end
	hList:SetH(nHeight)
	frame:SetVisible(nHeight > 0 or not MY_Focus.bAutoHide)
	frame:SetH(nHeight + frame:Lookup("", "Image_Title"):GetH())
end

-- ����ָ���Ľ���Handle
function D.UpdateItem(hItem, p)
	local dwType, dwID = p.dwType, p.dwID
	local KObject, info, bInfo = MY.Game.GetObject(dwType, dwID)
	local szName = p.tRule and p.tRule.display
	if not szName or szName == "" then
		szName = MY.Game.GetObjectName(KObject)
	end
	local player = GetClientPlayer()
	if not KObject then
		return
	end
	hItem.dwType = dwType
	hItem.dwID = dwID

	---------- ��� ----------
	-- Сͼ���б�
	local hInfoList = hItem:Lookup("Handle_InfoList")
	-- ����
	hInfoList:Lookup('Handle_Lock'):Hide()
	if dwType == l_dwLockType and dwID == l_dwLockID then
		l_lockInDisplay = true
		hInfoList:Lookup('Handle_Lock'):Show()
	end
	-- �ķ�
	hInfoList:Lookup('Handle_Kungfu'):Hide()
	if dwType == TARGET.PLAYER then
		if bInfo and info.dwMountKungfuID then
			hItem:Lookup('Handle_LMN/Text_Kungfu'):SetText(MY.GetKungfuName(info.dwMountKungfuID))
			hInfoList:Lookup('Handle_Kungfu'):Show()
			hInfoList:Lookup('Handle_Kungfu/Image_Kungfu'):FromIconID(Table_GetSkillIconID(info.dwMountKungfuID, 1))
		else
			local kungfu = KObject.GetKungfuMount()
			if kungfu then
				hItem:Lookup('Handle_LMN/Text_Kungfu'):SetText(MY.GetKungfuName(kungfu.dwSkillID))
				hInfoList:Lookup('Handle_Kungfu'):Show()
				hInfoList:Lookup('Handle_Kungfu/Image_Kungfu'):FromIconID(Table_GetSkillIconID(kungfu.dwSkillID, 1))
			else
				hItem:Lookup('Handle_LMN/Text_Kungfu'):SetText(g_tStrings.tForceTitle[KObject.dwForceID])
				hInfoList:Lookup('Handle_Kungfu'):Show()
				hInfoList:Lookup('Handle_Kungfu/Image_Kungfu'):FromUITex(GetForceImage(KObject.dwForceID))
			end
		end
	end
	-- ��Ӫ
	hInfoList:Lookup('Handle_Camp'):Hide()
	if dwType == TARGET.PLAYER
	and (KObject.nCamp == CAMP.GOOD or KObject.nCamp == CAMP.EVIL) then
		hInfoList:Lookup('Handle_Camp'):Show()
		hInfoList:Lookup('Handle_Camp/Image_Camp'):FromUITex(GetCampImage(KObject.nCamp, KObject.bCampFlag))
	end
	-- ���
	hInfoList:Lookup('Handle_Mark'):Hide()
	local KTeam = GetClientTeam()
	if KTeam and MY.IsInParty() then
		local tMark = KTeam.GetTeamMark()
		if tMark then
			local nMarkID = tMark[dwID]
			if nMarkID then
				hInfoList:Lookup('Handle_Mark'):Show()
				hInfoList:Lookup('Handle_Mark/Image_Mark'):FromUITex(PARTY_MARK_ICON_PATH, PARTY_MARK_ICON_FRAME_LIST[nMarkID])
			end
		end
	end
	hInfoList:FormatAllItemPos()

	-- Ŀ�����
	local nDistance = 0
	if player then
		nDistance = floor(sqrt(pow(player.nX - KObject.nX, 2) + pow(player.nY - KObject.nY, 2) + (MY_Focus.bDistanceZ and pow((player.nZ - KObject.nZ) / 8, 2) or 0)) * 10 / 64) / 10
	end
	hItem:Lookup('Handle_Compass/Compass_Distance'):SetText(nDistance)
	hItem:Lookup('Handle_School/School_Distance'):SetText(nDistance)
	-- ��������
	if player then
		hItem:Lookup('Handle_Compass/Image_Player'):Show()
		hItem:Lookup('Handle_Compass/Image_Player'):SetRotate( - player.nFaceDirection / 128 * math.pi)
	end
	-- �����Ҫ����
	if MY_Focus.bDisplayKungfuIcon and dwType == TARGET.PLAYER then
		hItem:Lookup('Handle_Compass'):Hide()
		hItem:Lookup('Handle_School'):Show()
		-- �ķ�ͼ��
		if bInfo and info.dwMountKungfuID then
			hItem:Lookup('Handle_School/Image_School'):FromIconID(Table_GetSkillIconID(info.dwMountKungfuID, 1))
		else
			local kungfu = KObject.GetKungfuMount()
			if kungfu then
				hItem:Lookup('Handle_School/Image_School'):FromIconID(Table_GetSkillIconID(kungfu.dwSkillID, 1))
			else
				hItem:Lookup('Handle_School/Image_School'):FromUITex(GetForceImage(KObject.dwForceID))
			end
		end
	else
		hItem:Lookup('Handle_School'):Hide()
		hItem:Lookup('Handle_Compass'):Show()
		-- ���λ��
		hItem:Lookup('Handle_Compass/Image_PointRed'):Hide()
		hItem:Lookup('Handle_Compass/Image_PointGreen'):Hide()
		if player and nDistance > 0 then
			local h
			if IsEnemy(UI_GetClientPlayerID(), dwID) then
				h = hItem:Lookup('Handle_Compass/Image_PointRed')
			else
				h = hItem:Lookup('Handle_Compass/Image_PointGreen')
			end
			h:Show()
			local nRotate = 0
			-- ���нǶ�
			if player.nX == KObject.nX then
				if player.nY > KObject.nY then
					nRotate = math.pi / 2
				else
					nRotate = - math.pi / 2
				end
			else
				nRotate = math.atan((player.nY - KObject.nY) / (player.nX - KObject.nX))
			end
			if nRotate < 0 then
				nRotate = nRotate + math.pi
			end
			if KObject.nY < player.nY then
				nRotate = math.pi + nRotate
			end
			local nRadius = 13.5
			h:SetRelPos((nRadius + nRadius * math.cos(nRotate) + 2) * MY_Focus.fScaleX, (nRadius - 3 - 13.5 * math.sin(nRotate)) * MY_Focus.fScaleY)
			h:GetParent():FormatAllItemPos()
		end
	end
	---------- �Ҳ� ----------
	-- ����
	hItem:Lookup('Handle_LMN/Text_Name'):SetText(szName or KObject.dwID)
	-- Ѫ��
	if dwType ~= TARGET.DOODAD then
		local nCurrentLife, nMaxLife = info.nCurrentLife, info.nMaxLife
		local nCurrentMana, nMaxMana = info.nCurrentMana, info.nMaxMana
		local szLife = ''
		if nCurrentLife > 10000 then
			szLife = szLife .. FormatString(g_tStrings.MPNEY_TENTHOUSAND, floor(nCurrentLife / 1000) / 10)
		else
			szLife = szLife .. nCurrentLife
		end
		if nMaxLife > 0 then
			local nPercent = floor(nCurrentLife / nMaxLife * 100)
			if nPercent > 100 then
				nPercent = 100
			end
			szLife = szLife .. '(' .. nPercent .. '%)'
			hItem:Lookup('Handle_LMN/Image_Health'):SetPercentage(nCurrentLife / nMaxLife)
			hItem:Lookup('Handle_LMN/Text_Health'):SetText(szLife)
		end
		if nMaxMana > 0 then
			hItem:Lookup('Handle_LMN/Image_Mana'):SetPercentage(nCurrentMana / nMaxMana)
			hItem:Lookup('Handle_LMN/Text_Mana'):SetText(nCurrentMana .. '/' .. nMaxMana)
		end
	end
	-- ����
	if dwType ~= TARGET.DOODAD then
		local nType, dwSkillID, dwSkillLevel, fProgress = KObject.GetSkillOTActionState()
		if MY_Focus.bTraversal and dwType == TARGET.PLAYER
		and (
			nType ~= CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
			and nType ~= CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL
			and KObject.GetOTActionState() == 1
		) then
			MY.WithTarget(dwType, dwID, function()
				local nType, dwSkillID, dwSkillLevel, fProgress = KObject.GetSkillOTActionState()
				if nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
				or nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL then
					hItem:Lookup('Handle_Progress/Image_Progress'):SetPercentage(fProgress)
					hItem:Lookup('Handle_Progress/Text_Progress'):SetText((MY.GetSkillName(dwSkillID, dwSkillLevel)))
				else
					hItem:Lookup('Handle_Progress/Image_Progress'):SetPercentage(0)
					hItem:Lookup('Handle_Progress/Text_Progress'):SetText('')
				end
			end)
		else
			if nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
			or nType == CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL then
				hItem:Lookup('Handle_Progress/Image_Progress'):SetPercentage(fProgress)
				hItem:Lookup('Handle_Progress/Text_Progress'):SetText((MY.GetSkillName(dwSkillID, dwSkillLevel)))
			else
				hItem:Lookup('Handle_Progress/Image_Progress'):SetPercentage(0)
				hItem:Lookup('Handle_Progress/Text_Progress'):SetText('')
			end
		end
	end
	-- Ŀ���Ŀ��
	if MY_Focus.bShowTarget and dwType ~= TARGET.DOODAD then
		local tp, id = KObject.GetTarget()
		local tar = MY.Game.GetObject(tp, id)
		if tar then
			hItem:Lookup('Handle_Progress/Text_Target'):SetText(MY.Game.GetObjectName(tar) or tar.dwID)
		else
			hItem:Lookup('Handle_Progress/Text_Target'):SetText('')
		end
	end
	-- ѡ��״̬
	hItem:Lookup('Image_Select'):Hide()
	if player then
		local dwTargetType, dwTargetID = player.GetTarget()
		if dwTargetType == dwType and dwTargetID == dwID then
			hItem:Lookup('Image_Select'):Show()
		end
	end
	hItem:FormatAllItemPos()
end

-- �����б�
function D.UpdateList(frame)
	l_lockInDisplay = false
	local nCount = 0
	local hList = frame:Lookup("", "Handle_List")
	local aList = MY_Focus.GetDisplayList()
	for i = 1, hList:GetItemCount() do
		local p = aList[i]
		local hItem = hList:Lookup(i - 1)
		if p then
			if not hItem:IsVisible() then
				hItem:Show()
			end
			D.UpdateItem(hItem, p)
			nCount = nCount + 1
		elseif hItem:IsVisible() then
			hItem:Hide()
		end
	end
	if frame.nCount ~= nCount then
		D.AutosizeUI(frame)
		frame.nCount = nCount
	end
end

-- ########################################################################## --
--                                     #                 #         #          --
--                           # # # # # # # # # # #       #   #     #          --
--   # #     # # # # # # #       #     #     #         #     #     #          --
--     #     #       #           # # # # # # #         #     # # # # # # #    --
--     #     #       #                 #             # #   #       #          --
--     #     #       #         # # # # # # # # #       #           #          --
--     #     #       #                 #       #       #           #          --
--     #     #       #       # # # # # # # # # # #     #   # # # # # # # #    --
--     #     #       #                 #       #       #           #          --
--       # #     # # # # #     # # # # # # # # #       #           #          --
--                                     #               #           #          --
--                                   # #               #           #          --
-- ########################################################################## --
-- �����ػ�
function MY_Focus.OnFrameBreathe()
	if not MY_Focus.IsShielded() then
		if l_dwLockType and l_dwLockID and l_lockInDisplay then
			local dwType, dwID = MY.GetTarget()
			if dwType ~= l_dwLockType or dwID ~= l_dwLockID then
				MY.SetTarget(l_dwLockType, l_dwLockID)
			end
		end
		if MY_Focus.bSortByDistance then
			MY_Focus.SortFocus()
		end
	end
	D.UpdateList(this)
end

function MY_Focus.OnFrameCreate()
	this:RegisterEvent("PARTY_SET_MARK")
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("PLAYER_ENTER_SCENE")
	this:RegisterEvent("NPC_ENTER_SCENE")
	this:RegisterEvent("DOODAD_ENTER_SCENE")
	this:RegisterEvent("PLAYER_LEAVE_SCENE")
	this:RegisterEvent("NPC_LEAVE_SCENE")
	this:RegisterEvent("DOODAD_LEAVE_SCENE")
	this:RegisterEvent("MY_SET_IMPORTANT_NPC")
	this:RegisterEvent("MY_FOCUS_LOCK_UPDATE")
	this:RegisterEvent("MY_FOCUS_SCALE_UPDATE")
	this:RegisterEvent("MY_FOCUS_MAX_DISPLAY_UPDATE")

	D.Scale(this)
	D.CreateList(this)
	MY_Focus.OnEvent("UI_SCALED")
	MY_Focus.RescanNearby()
end

function MY_Focus.OnEvent(event)
	if event == "PARTY_SET_MARK" then
		D.UpdateList(this)
	elseif event == 'UI_SCALED' then
		XGUI(this):anchor(MY_Focus.anchor)
	elseif event == 'PLAYER_ENTER_SCENE' then
		MY_Focus.OnObjectEnterScene(TARGET.PLAYER, arg0)
	elseif event == 'NPC_ENTER_SCENE' then
		MY_Focus.OnObjectEnterScene(TARGET.NPC, arg0)
	elseif event == 'DOODAD_ENTER_SCENE' then
		MY_Focus.OnObjectEnterScene(TARGET.DOODAD, arg0)
	elseif event == 'PLAYER_LEAVE_SCENE' then
		MY_Focus.OnObjectLeaveScene(TARGET.PLAYER, arg0)
	elseif event == 'NPC_LEAVE_SCENE' then
		MY_Focus.OnObjectLeaveScene(TARGET.NPC, arg0)
	elseif event == 'DOODAD_LEAVE_SCENE' then
		MY_Focus.OnObjectLeaveScene(TARGET.DOODAD, arg0)
	elseif event == 'MY_SET_IMPORTANT_NPC' then
		MY_Focus.RescanNearby()
	elseif event == 'MY_FOCUS_LOCK_UPDATE' then
		D.UpdateList(this)
	elseif event == 'MY_FOCUS_SCALE_UPDATE' then
		D.Scale(this)
	elseif event == 'MY_FOCUS_MAX_DISPLAY_UPDATE' then
		D.CreateList(this)
	end
end

function MY_Focus.OnFrameDragSetPosEnd()
	this:CorrectPos()
	MY_Focus.anchor = MY.UI(this):anchor('TOPRIGHT')
end

function MY_Focus.OnItemMouseEnter()
	local name = this:GetName()
	if name == "Handle_Info" then
		this:Lookup("Image_Hover"):Show()
		if MY_Focus.bHealHelper then
			this.dwLastType, this.dwLastID = MY.GetTarget()
			MY_Focus.OnItemLButtonClick()
		end
	end
end

function MY_Focus.OnItemMouseLeave()
	local name = this:GetName()
	if name == "Handle_Info" then
		if this:Lookup("Image_Hover") then
			this:Lookup("Image_Hover"):Hide()
			if MY_Focus.bHealHelper then
				MY.SetTarget(this.dwLastType, this.dwLastID)
				this.dwLastType, this.dwLastID = nil
			end
		end
	end
end

function MY_Focus.OnItemLButtonClick()
	local name = this:GetName()
	if name == "Handle_Info" then
		if MY_Focus.bHealHelper then
			this.dwLastType, this.dwLastID = this.dwType, this.dwID
		end
		SetTarget(this.dwType, this.dwID)
	end
end

function MY_Focus.OnItemRButtonClick()
	local name = this:GetName()
	if name == "Handle_Info" then
		local dwType, dwID = this.dwType, this.dwID
		local t = MY.Game.GetTargetContextMenu(dwType, this:Lookup('Handle_LMN/Text_Name'):GetText(), dwID)
		table.insert(t, 1, {
			szOption = _L['delete focus'],
			fnAction = function()
				if l_dwLockType == dwType and l_dwLockID == dwID then
					l_dwLockType = nil
					l_dwLockID = nil
				end
				MY_Focus.RemoveFocusID(dwType, dwID)
			end,
		})
		local bLock = dwType == l_dwLockType and dwID == l_dwLockID
		table.insert(t, {
			szOption = bLock and _L['unlock focus'] or _L['lock focus'],
			fnAction = function()
				if bLock then
					l_dwLockID = nil
					l_dwLockType = nil
				else
					l_dwLockID = dwID
					l_dwLockType = dwType
					MY.SetTarget(dwType, dwID)
				end
				FireUIEvent("MY_FOCUS_LOCK_UPDATE")
			end,
		})
		PopupMenu(t)
	end
end

function MY_Focus.OnLButtonClick()
	local name = this:GetName()
	if name == 'Btn_Setting' then
		MY.OpenPanel()
		MY.SwitchTab('MY_Focus')
	end
end

function MY_Focus.OnCheckBoxCheck()
	local name = this:GetName()
	if name == 'CheckBox_Minimize' then
		MY_Focus.bMinimize = true
	end
end

function MY_Focus.OnCheckBoxUncheck()
	local name = this:GetName()
	if name == 'CheckBox_Minimize' then
		MY_Focus.bMinimize = false
	end
end

MY.RegisterInit('MY_FOCUS', function()
	if MY_Focus.bEnable then
		MY_Focus.Open()
	else
		MY_Focus.Close()
	end
end)
