---------------------------------
-- �������
-- by������@˫����@׷����Ӱ
-- ref: �����������Դ�� @haimanchajian.com
---------------------------------
-----------------------------------------------
-- ���غ����ͱ���
-----------------------------------------------
MY = { }
--[[ �����Դ���
    (table) MY.LoadLangPack(void)
]]
MY.LoadLangPack = function()
	local _, _, szLang = GetVersion()
	local t0 = LoadLUAData("interface\\MY\\lang\\default.lua") or {}
	local t1 = LoadLUAData("interface\\MY\\lang\\" .. szLang .. ".lua") or {}
	for k, v in pairs(t0) do
		if not t1[k] then
			t1[k] = v
		end
	end
	setmetatable(t1, {
		__index = function(t, k) return k end,
		__call = function(t, k, ...) return string.format(t[k], ...) end,
	})
	return t1
end
local _L = MY.LoadLangPack()
-----------------------------------------------
-- ˽�к���
-----------------------------------------------
local _MY = {
    frame = nil,
    hBox = nil,
    hRequest = nil,
    bLoaded = false,
    nDebugLevel = 4,
    dwVersion = 0x0000301,
    szBuildDate = "20140419",
    szName = _L["mingyi plugins"],
    szShortName = _L["mingyi plugin"],
    szIniFile = "Interface\\MY\\ui\\MY.ini",
    szIniFileTabBox = "Interface\\MY\\ui\\WndTabBox.ini",
    szIniFileMainPanel = "Interface\\MY\\ui\\MainPanel.ini",
    tNearNpc = {},      -- ������NPC
    tNearPlayer = {},   -- ���������
    tNearDoodad = {},   -- ��������Ʒ
    tPlayerSkills = {}, -- ��Ҽ����б�[����]
    tBreatheCall = {},  -- breathe call ����
    tDelayCall = {},    -- delay call ����
    tRequest = {},      -- �����������
    bRequest = false,   -- ��������æ��
    tTabs = {},         -- ��ǩҳ
    tEvent = {},        -- ��Ϸ�¼���
    tPlayerMenu = {},   -- ���ͷ��˵�
    tTargetMenu = {},   -- Ŀ��ͷ��˵�
    tTraceMenu  = {},   -- �������˵�
}
_MY.Init = function()
    if _MY.bLoaded then return end
	-- var
    _MY.bLoaded = true
	_MY.hBox = MY.GetFrame():Lookup("","Box_1")
	_MY.hRequest = MY.GetFrame():Lookup("Page_1")
    -- ���ڰ�ť
    MY.UI(MY.GetFrame()):find("#Button_WindowClose"):click(function() _MY.ClosePanel() end)
    -- �����˵�
    local tMenu = function() return {
        szOption = _L["mingyi plugins"],
        fnAction = function()
            Station.Lookup("Normal/MY"):ToggleVisible()
        end,
        bCheck = true,
        bChecked = Station.Lookup("Normal/MY"):IsVisible(),
    } end
    MY.RegisterPlayerAddonMenu( 'MY_MAIN_MENU', tMenu)
    MY.RegisterTraceButtonMenu( 'MY_MAIN_MENU', tMenu)
    -- ��ʾ��ӭ��Ϣ
    MY.Sysmsg(_L("%s, welcome to use mingyi plugins!", GetClientPlayer().szName) .. " v" .. MY.GetVersion() .. ' Build ' .. _MY.szBuildDate .. "\n")
    if _MY.nDebugLevel >=3 then _MY.frame:Hide() end
end
-- get channel header
_MY.tTalkChannelHeader = {
	[PLAYER_TALK_CHANNEL.NEARBY] = "/s ",
	[PLAYER_TALK_CHANNEL.FRIENDS] = "/o ",
	[PLAYER_TALK_CHANNEL.TONG_ALLIANCE] = "/a ",
	[PLAYER_TALK_CHANNEL.RAID] = "/t ",
	[PLAYER_TALK_CHANNEL.BATTLE_FIELD] = "/b ",
	[PLAYER_TALK_CHANNEL.TONG] = "/g ",
	[PLAYER_TALK_CHANNEL.SENCE] = "/y ",
	[PLAYER_TALK_CHANNEL.FORCE] = "/f ",
	[PLAYER_TALK_CHANNEL.CAMP] = "/c ",
	[PLAYER_TALK_CHANNEL.WORLD] = "/h ",
}
-- parse faceicon in talking message
_MY.ParseFaceIcon = function(t)
	if not _MY.tFaceIcon then
		_MY.tFaceIcon = {}
		for i = 1, g_tTable.FaceIcon:GetRowCount() do
			local tLine = g_tTable.FaceIcon:GetRow(i)
			_MY.tFaceIcon[tLine.szCommand] = true
		end
	end
	local t2 = {}
	for _, v in ipairs(t) do
		if v.type ~= "text" then
			if v.type == "faceicon" then
				v.type = "text"
			end
			table.insert(t2, v)
		else
			local nOff, nLen = 1, string.len(v.text)
			while nOff <= nLen do
				local szFace = nil
				local nPos = StringFindW(v.text, "#", nOff)
				if not nPos then
					nPos = nLen
				else
					for i = nPos + 6, nPos + 2, -2 do
						if i <= nLen then
							local szTest = string.sub(v.text, nPos, i)
							if _MY.tFaceIcon[szTest] then
								szFace = szTest
								nPos = nPos - 1
								break
							end
						end
					end
				end
				if nPos >= nOff then
					table.insert(t2, { type = "text", text = string.sub(v.text, nOff, nPos) })
					nOff = nPos + 1
				end
				if szFace then
					table.insert(t2, { type = "text", text = szFace })
					nOff = nOff + string.len(szFace)
				end
			end
		end
	end
	return t2
end
-- parse name in talking message
_MY.ParseName = function(t)
	local t2 = {}
	for _, v in ipairs(t) do
		if v.type ~= "text" then
			if v.type == "name" then
				v = { type = "text", text = "["..v.name.."]" }
			end
			table.insert(t2, v)
		else
			local nOff, nLen = 1, string.len(v.text)
			while nOff <= nLen do
				local szName = nil
				local nPos1, nPos2 = string.find(v.text, '%[[^%[%]]+%]', nOff)
				if not nPos1 then
					nPos1 = nLen
				else
					szName = string.sub(v.text, nPos1 + 1, nPos2 - 1)
                    nPos1 = nPos1 - 1
				end
				if nPos1 >= nOff then
					table.insert(t2, { type = "text", text = string.sub(v.text, nOff, nPos1) })
					nOff = nPos1 + 1
				end
				if szName then
					table.insert(t2, { type = "name", name = szName })
					nOff = nPos2 + 1
				end
			end
		end
	end
	return t2
end
-- close window
_MY.ClosePanel = function(bRealClose)
	local frame = Station.Lookup("Normal/MY")
	if frame then
		if not bRealClose then
			frame:Hide()
		else
			Wnd.CloseWindow(frame)
			_MY.frame = nil
		end
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
end
-- open window
_MY.OpenPanel = function()
    local frame = MY.GetFrame()
    frame:Show()
end
-- get player addon menu
_MY.GetPlayerAddonMenu = function()
    local menu = {}
    table.insert(menu, { bDevide = true })
    for i = 1, #_MY.tPlayerMenu, 1 do
        local m = _MY.tPlayerMenu[i].Menu
        if type(m)=="function" then m = m() end
        table.insert(menu, m)
    end
    if #menu==1 then menu={} end
    return menu
end
-- get target addon menu
_MY.GetTargetAddonMenu = function()
    local menu = {}
    table.insert(menu, { bDevide = true })
    for i = 1, #_MY.tTargetMenu, 1 do
        local m = _MY.tTargetMenu[i].Menu
        if type(m)=="function" then m = m() end
        table.insert(menu, m)
    end
    if #menu==1 then menu={} end
    return menu
end
-- get trace button menu
_MY.GetTraceButtonMenu = function()
    local menu = {}
    table.insert(menu, { bDevide = true })
    for i = 1, #_MY.tTraceMenu, 1 do
        local m = _MY.tTraceMenu[i].Menu
        if type(m)=="function" then m = m() end
        table.insert(menu, m)
    end
    if #menu==1 then menu={} end
    return menu
end
-----------------------------------------------
-- ͨ�ú���
-----------------------------------------------
-- (string, number) MY.GetVersion()		-- HM�� ��ȡ�ַ����汾�� �޸ķ����ù�����
MY.GetVersion = function()
	local v = _MY.dwVersion
	local szVersion = string.format("%d.%d.%d", v/0x1000000,
		math.floor(v/0x10000)%0x100, math.floor(v/0x100)%0x100)
	if  v%0x100 ~= 0 then
		szVersion = szVersion .. "b" .. tostring(v%0x100)
	end
	return szVersion, v
end
--[[ ��ȡ��������
    (frame) MY.GetFrame()
]]
MY.GetFrame = function() 
    if not _MY.frame then 
        _MY.frame = Wnd.OpenWindow(_MY.szIniFile, "MY")
    end
    return _MY.frame
end
MY.ClosePanel = _MY.ClosePanel
MY.OpenPanel = _MY.OpenPanel
-- (void) MY.MenuTip(string str)	-- MenuTip
MY.MenuTip = function(str)
	local szText="<image>path=\"ui/Image/UICommon/Talk_Face.UITex\" frame=25 w=24 h=24</image> <text>text=" .. EncodeComponentsString(str) .." font=207 </text>"
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	OutputTip(szText, 450, {x, y, w, h})
end
--[[ (void) MY.RemoteRequest(string szUrl, func fnAction)		-- ����Զ�� HTTP ����
-- szUrl		-- ��������� URL������ http:// �� https://��
-- fnAction 	-- ������ɺ�Ļص��������ص�ԭ�ͣ�function(szTitle, szContent)]]
MY.RemoteRequest = function(szUrl, fnSuccess, fnError, nTimeout)
    -- ��ʽ������
    if type(szUrl)~="string" then return end
    if type(fnSuccess)~="function" then return end
    if type(fnError)~="function" then fnError = function(szUrl,errMsg) MY.Debug(szUrl..' - '..errMsg.."\n",'RemoteRequest',1) end end
    if type(nTimeout)~="number" then nTimeout = 10000 end
    -- ���������β����������
	table.insert(_MY.tRequest,{ szUrl = szUrl, fnSuccess = fnSuccess, fnError = fnError, nTimeout = nTimeout })
    -- ��ʼ�����������
    _MY.DoRemoteRequest()
end
-- ����Զ���������
_MY.DoRemoteRequest = function()
    -- �������Ϊ�� ���ö���״̬Ϊ���в�����
    if table.getn(_MY.tRequest)==0 then _MY.bRequest = false MY.Debug('Remote Request Queue Is Clear.\n','MYRR',0) return end
    -- �����ǰ������δ��������� ����Զ��������д��ڿ���״̬
    if not _MY.bRequest then
        -- check if network plugins inited
        if not _MY.hRequest then
            MY.DelayCall( _MY.DoRemoteRequest, 3000 )
            MY.Debug('network plugin has not been initalized yet!\n','MYRR',1)
            _MY.hRequest = MY.GetFrame():Lookup("Page_1")
            return
        end
        -- ��ȡ���е�һ��Ԫ��
        local rr = _MY.tRequest[1]
        -- ע������ʱ��������ʱ��
        MY.DelayCall(function()
            -- debug
            MY.Debug('Remote Request Timeout.\n','MYRR',1)
            -- ����ʱ �ص�����ʱ����
            pcall(rr.fnError, rr.szUrl, "timeout")
            -- ����������Ƴ���Ԫ��
            table.remove(_MY.tRequest, 1)
            -- �����������״̬Ϊ����
            _MY.bRequest = false
            -- ������һ��Զ������
            _MY.DoRemoteRequest()
        end,rr.nTimeout,"MY_Remote_Request_Timeout")
        -- ��ʼ����������Դ
        _MY.hRequest:Navigate(rr.szUrl)
        -- ���������״̬Ϊ��æ��
        _MY.bRequest = true
    end
end
--[[ ��N2��N1�������  --  ����+2
    -- ����N1���ꡢ����N2���� 
    (number) MY.GetFaceToTargetDegree(nX,nY,nFace,nTX,nTY)
    -- ����N1��N2
    (number) MY.GetFaceToTargetDegree(oN1, oN2)
    -- ���
    nil -- ��������
    number -- �����(0-180)
]]
MY.GetFaceDegree = function(nX,nY,nFace,nTX,nTY)
    if type(nY)=="userdata" and type(nX)=="userdata" then nTX=nY.nX nTY=nY.nY nY=nX.nY nFace=nX.nFaceDirection nX=nX.nX end
    if type(nX)~="number" or type(nY)~="number" or type(nFace)~="number" or type(nTX)~="number" or type(nTY)~="number" then return nil end
    local a = nFace * math.pi / 128
    return math.acos( ( (nTX-nX)*math.cos(a) + (nTY-nY)*math.sin(a) ) / ( (nTX-nX)^2 + (nTY-nY)^2) ^ 0.5 ) * 180 / math.pi
end
--[[ ��oT2��oT1�����滹�Ǳ���
    (bool) MY.IsFaceToTarget(oT1,oT2)
    -- ���淵��true
    -- ���Է���false
    -- ��������ȷʱ����nil
]]
MY.IsFaceToTarget = function(oT1,oT2)
    if type(oT1)~="userdata" or type(oT2)~="userdata" then return nil end
    local a = oT1.nFaceDirection * math.pi / 128
    return (oT2.nX-oT1.nX)*math.cos(a) + (oT2.nY-oT1.nY)*math.sin(a) > 0
end
--[[ װ����ΪszName��װ��
    (void) MY.Equip(szName)
    szName  װ������
]]
MY.Equip = function(szName)
    local me = GetClientPlayer()
    for i=1,6 do
        if me.GetBoxSize(i)>0 then
            for j=0, me.GetBoxSize(i)-1 do
                local item = me.GetItem(i,j)
                if item == nil then
                    j=j+1
                elseif GetItemNameByItem(item)==szName then
                    local eRetCode, nEquipPos = me.GetEquipPos(i, j)
                    if szName==_L["ji guan"] or szName==_L["nu jian"] then
                        for k=0,15 do
                            if me.GetItem(INVENTORY_INDEX.BULLET_PACKAGE, k) == nil then
                                OnExchangeItem(i, j, INVENTORY_INDEX.BULLET_PACKAGE, k)
                                return
                            end
                        end
                        return
                    else
                        OnExchangeItem(i, j, INVENTORY_INDEX.EQUIP, nEquipPos)
                        return
                    end
                end
            end
        end
    end
end
--[[ ��ȡ�����buff�б�
    (table) MY.GetBuffList(obj)
]]
MY.GetBuffList = function(obj)
    local aBuffTable = {}
    local nCount = obj.GetBuffCount() or 0
    for i=1,nCount,1 do
        local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid = obj.GetBuff(i - 1)
        if dwID then
            table.insert(aBuffTable,{dwID = dwID, nLevel = nLevel, bCanCancel = bCanCancel, nEndFrame = nEndFrame, nIndex = nIndex, nStackNum = nStackNum, dwSkillSrcID = dwSkillSrcID, bValid = bValid})
        end
    end
    return aBuffTable
end
--[[ ͨ���������ƻ�ȡ���ܶ���
    (table) MY.GetSkillByName(szName)
]]
MY.GetSkillByName = function(szName) 
	if table.getn(_MY.tPlayerSkills)==0 then
        for i = 1, g_tTable.Skill:GetRowCount() do
            local tLine = g_tTable.Skill:GetRow(i)
            if tLine~=nil and tLine.dwIconID~=nil and tLine.fSortOrder~=nil and tLine.szName~=nil and tLine.dwIconID~=13 and ( (not _MY.tPlayerSkills[tLine.szName]) or tLine.fSortOrder>_MY.tPlayerSkills[tLine.szName].fSortOrder) then
                _MY.tPlayerSkills[tLine.szName] = tLine
            end
        end
    end
    return _MY.tPlayerSkills[szName]
end
--[[ �жϼ��������Ƿ���Ч
    (bool) MY.IsValidSkill(szName)
]]
MY.IsValidSkill = function(szName)
    if MY.GetSkillByName(szName)==nil then return false else return true end
end
--[[ �жϵ�ǰ�û��Ƿ����ĳ������
    (bool) MY.CanUseSkill(number dwSkillID[, dwLevel])
]]
MY.CanUseSkill = function(dwSkillID, dwLevel)
    -- �жϼ����Ƿ���Ч ����������ת��Ϊ����ID
    if type(dwSkillID) == "string" then if MY.IsValidSkill(dwSkillID) then dwSkillID = MY.GetSkillByName(dwSkillID).dwSkillID else return false end end
	local me, box = GetClientPlayer(), _MY.hBox
	if me and box then
		if not dwLevel then
			if dwSkillID ~= 9007 then
				dwLevel = me.GetSkillLevel(dwSkillID)
			else
				dwLevel = 1
			end
		end
		if dwLevel > 0 then
			box:EnableObject(false)
			box:SetObjectCoolDown(1)
			box:SetObject(UI_OBJECT_SKILL, dwSkillID, dwLevel)
			UpdataSkillCDProgress(me, box)
			return box:IsObjectEnable() and not box:IsObjectCoolDown()
		end
	end
	return false
end
--[[ �ͷż���,�ͷųɹ�����true
    (bool)MY.UseSkill(dwSkillID, bForceStopCurrentAction, eTargetType, dwTargetID)
    dwSkillID               ����ID
    bForceStopCurrentAction �Ƿ��ϵ�ǰ�˹�
    eTargetType             �ͷ�Ŀ������
    dwTargetID              �ͷ�Ŀ��ID
]]
MY.UseSkill = function(dwSkillID, bForceStopCurrentAction, eTargetType, dwTargetID)
    -- �жϼ����Ƿ���Ч ����������ת��Ϊ����ID
    if type(dwSkillID) == "string" then if MY.IsValidSkill(dwSkillID) then dwSkillID = MY.GetSkillByName(dwSkillID).dwSkillID else return false end end
    local me = GetClientPlayer()
    -- ��ȡ����CD
    local bCool, nLeft, nTotal = me.GetSkillCDProgress( dwSkillID, me.GetSkillLevel(dwSkillID) ) local bIsPrepare ,dwPreSkillID ,dwPreSkillLevel , fPreProgress= me.GetSkillPrepareState()
	local oTTP, oTID = me.GetTarget()
    if dwTargetID~=nil then SetTarget(eTargetType, dwTargetID) end
    if ( not bCool or nLeft == 0 and nTotal == 0 ) and not ( not bForceStopCurrentAction and dwPreSkillID == dwSkillID ) then
        me.StopCurrentAction() OnAddOnUseSkill( dwSkillID, me.GetSkillLevel(dwSkillID) )
        if dwTargetID then SetTarget(oTTP, oTID) end
        return true
    else
        if dwTargetID then SetTarget(oTTP, oTID) end
        return false
    end
end
--[[ �ǳ���Ϸ
    (void) MY.LogOff(bCompletely)
    bCompletely Ϊtrue���ص�½ҳ Ϊfalse���ؽ�ɫҳ Ĭ��Ϊfalse
]]
MY.LogOff = function(bCompletely)
    if bCompletely then
        ReInitUI(LOAD_LOGIN_REASON.RETURN_GAME_LOGIN)
    else
        ReInitUI(LOAD_LOGIN_REASON.RETURN_ROLE_LIST)
    end
end
--[[ ��ȡ����NPC�б�
    (table) MY.GetNearNpc(void)
]]
MY.GetNearNpc = function(nLimit)
    local tNpc, i = {}, 0
    for dwID, _ in pairs(_MY.tNearNpc) do
        local npc = GetNpc(dwID)
        if not npc then
            _MY.tNearNpc[dwID] = nil
        else
            i = i + 1
            tNpc[dwID] = npc
            if nLimit and i == nLimit then break end
        end
    end
    return tNpc, i
end
--[[ ��ȡ��������б�
    (table) MY.GetNearPlayer(void)
]]
MY.GetNearPlayer = function(nLimit)
    local tPlayer, i = {}, 0
    for dwID, _ in pairs(_MY.tNearPlayer) do
        local player = GetPlayer(dwID)
        if not player then
            _MY.tNearPlayer[dwID] = nil
        else
            i = i + 1
            tPlayer[dwID] = player
            if nLimit and i == nLimit then break end
        end
    end
    return tPlayer, i
end
--[[ ��ȡ������Ʒ�б�
    (table) MY.GetNearPlayer(void)
]]
MY.GetNearDoodad = function(nLimit)
    local tDoodad, i = {}, 0
    for dwID, _ in pairs(_MY.tNearDoodad) do
        local dooded = GetDoodad(dwID)
        if not dooded then
            _MY.tNearDoodad[dwID] = nil
        else
            i = i + 1
            tDoodad[dwID] = dooded
            if nLimit and i == nLimit then break end
        end
    end
    return tDoodad, i
end
--[[ (KObject) MY.GetTarget()														-- ȡ�õ�ǰĿ���������
-- (KObject) MY.GetTarget([number dwType, ]number dwID)	-- ���� dwType ���ͺ� dwID ȡ�ò�������]]
MY.GetTarget = function(dwType, dwID)
	if not dwType then
		local me = GetClientPlayer()
		if me then
			dwType, dwID = me.GetTarget()
		else
			dwType, dwID = TARGET.NO_TARGET, 0
		end
	elseif not dwID then
		dwID, dwType = dwType, TARGET.NPC
		if IsPlayer(dwID) then
			dwType = TARGET.PLAYER
		end
	end
	if dwID <= 0 or dwType == TARGET.NO_TARGET then
		return nil, TARGET.NO_TARGET
	elseif dwType == TARGET.PLAYER then
		return GetPlayer(dwID), TARGET.PLAYER
	elseif dwType == TARGET.DOODAD then
		return GetDoodad(dwID), TARGET.DOODAD
	else
		return GetNpc(dwID), TARGET.NPC
	end
end
--[[ ���� dwType ���ͺ� dwID ����Ŀ��
-- (void) MY.SetTarget([number dwType, ]number dwID)
-- dwType	-- *��ѡ* Ŀ������
-- dwID		-- Ŀ�� ID]]
MY.SetTarget = function(dwType, dwID)
    if type(dwType)=="string" then dwType, dwID = 0, dwType end
    if type(dwID)=="string" then
        for _, p in pairs(MY.GetNearNpc()) do
            if p.szName == dwID then
                dwType, dwID = TARGET.NPC, p.dwID
            end
        end
    end
    if type(dwID)=="string" then
        for _, p in pairs(MY.GetNearPlayer()) do
            if p.szName == dwID then
                dwType = TARGET.PLAYER
                dwID = p.dwID
            end
        end
    end
	if not dwType or dwType <= 0 then
		dwType, dwID = TARGET.NO_TARGET, 0
	elseif not dwID then
		dwID, dwType = dwType, TARGET.NPC
		if IsPlayer(dwID) then
			dwType = TARGET.PLAYER
		end
	end
	SetTarget(dwType, dwID)
end
--[[ �ж�ĳ��Ƶ���ܷ���
-- (bool) MY.CanTalk(number nChannel)]]
MY.CanTalk = function(nChannel)
	for _, v in ipairs({"WHISPER", "TEAM", "RAID", "BATTLE_FIELD", "NEARBY", "TONG", "TONG_ALLIANCE" }) do
		if nChannel == PLAYER_TALK_CHANNEL[v] then
			return true
		end
	end
	return false
end
--[[ �л�����Ƶ��
-- (void) MY.SwitchChat(number nChannel)]]
MY.SwitchChat = function(nChannel)
	local szHeader = _MY.tTalkChannelHeader[nChannel]
	if szHeader then
		SwitchChatChannel(szHeader)
	elseif type(nChannel) == "string" then
		SwitchChatChannel("/w " .. string.gsub(nChannel,'[%[%]]','') .. " ")
	end
end
--[[ ������������
-- (void) MY.Talk(string szTarget, string szText[, boolean bNoEscape])
-- (void) MY.Talk([number nChannel, ] string szText[, boolean bNoEscape])
-- szTarget			-- ���ĵ�Ŀ���ɫ��
-- szText				-- �������ݣ������Ϊ���� KPlayer.Talk �� table��
-- nChannel			-- *��ѡ* ����Ƶ����PLAYER_TALK_CHANNLE.*��Ĭ��Ϊ����
-- bNoEscape	-- *��ѡ* ���������������еı���ͼƬ�����֣�Ĭ��Ϊ false
-- bSaveDeny	-- *��ѡ* �������������������ɷ��Ե�Ƶ�����ݣ�Ĭ��Ϊ false
-- �ر�ע�⣺nChannel, szText ���ߵĲ���˳����Ե�����ս��/�Ŷ�����Ƶ�������л�]]
MY.Talk = function(nChannel, szText, bNoEscape, bSaveDeny)
	local szTarget, me = "", GetClientPlayer()
	-- channel
	if not nChannel then
		nChannel = PLAYER_TALK_CHANNEL.NEARBY
	elseif type(nChannel) == "string" then
		if not szText then
			szText = nChannel
			nChannel = PLAYER_TALK_CHANNEL.NEARBY
		elseif type(szText) == "number" then
			szText, nChannel = nChannel, szText
		else
			szTarget = nChannel
			nChannel = PLAYER_TALK_CHANNEL.WHISPER
		end
	elseif nChannel == PLAYER_TALK_CHANNEL.RAID and me.GetScene().nType == MAP_TYPE.BATTLE_FIELD then
		nChannel = PLAYER_TALK_CHANNEL.BATTLE_FIELD
	end
	-- say body
	local tSay = nil
	if type(szText) == "table" then
		tSay = szText
	else
		local tar = MY.GetTarget(me.GetTarget())
		szText = string.gsub(szText, "%$zj", '['..me.szName..']')
		if tar then
			szText = string.gsub(szText, "%$mb", '['..tar.szName..']')
		end
		tSay = {{ type = "text", text = szText .. "\n"}}
	end
	if not bNoEscape then
		tSay = _MY.ParseFaceIcon(tSay)
		tSay = _MY.ParseName(tSay)
	end
	me.Talk(nChannel, szTarget, tSay)
	if bSaveDeny and not MY.CanTalk(nChannel) then
		local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
		edit:ClearText()
		for _, v in ipairs(tSay) do
			if v.type == "text" then
				edit:InsertText(v.text)
			else
				edit:InsertObj(v.text, v)
			end
		end
		-- change to this channel
		MY.SwitchChat(nChannel)
	end
end
--[[ ��ʾ������Ϣ
    MY.Sysmsg(szContent, szPrefix)
    szContent   Ҫ��ʾ��������Ϣ
    szPrefix    ��Ϣͷ��
    tContentCol ������Ϣ������ɫrgb[��ѡ��Ϊ��ʹ��Ĭ����ɫ��]
    tPrefixCol  ��Ϣͷ��������ɫrgb[��ѡ��Ϊ�պ�������Ϣ������ɫ��ͬ��]
]]
MY.Sysmsg = function(szContent, szPrefix, tContentCol, tPrefixCol)
    if type(szContent)=="boolean" then szContent = (szContent and 'true') or 'false' end
    szPrefix = szPrefix or _MY.szShortName
    if tContentCol then
        tPrefixCol = tPrefixCol or tContentCol
        OutputMessage("MSG_SYS", string.format(
            '<text>text="[%s] " font=10 r=%d g=%d b=%d</text><text>text="%s" font=10 r=%d g=%d b=%d</text>',
            string.gsub(szPrefix, '"','\\"'), tPrefixCol[1]  or 0, tPrefixCol[2]  or 0, tPrefixCol[3]  or 0,
            string.gsub(szContent,'"','\\"'), tContentCol[1] or 0, tContentCol[2] or 0, tContentCol[3] or 0
        ), true)
    else
        OutputMessage("MSG_SYS", string.format("[%s] %s", szPrefix, szContent) )
    end
end
--[[ Debug���
    (void)MY.Debug(szText, szHead, nLevel)
    szText  Debug��Ϣ
    szHead  Debugͷ
    nLevel  Debug����[���ڵ�ǰ����ֵ���������]
]]
MY.Debug = function(szText, szHead, nLevel)
    if type(nLevel)~="number" then nLevel = 1 end
    if type(szHead)~="string" then szHead = 'MY DEBUG' end
    local color = { 255, 255, 0 }
    if nLevel == 0 then
        color = { 0, 255, 127 }
    elseif nLevel == 1 then
        color = { 255, 170, 170 }
    elseif nLevel == 2 then
        color = { 255, 86, 86 }
    end
    if nLevel >= _MY.nDebugLevel then
        MY.Sysmsg(szText, szHead, color)
    end
end
--[[ �ӳٵ���
    (void) MY.DelayCall(func fnAction, number nDelay, string szName)
    fnAction	-- ���ú���
    nTime		-- �ӳٵ���ʱ�䣬��λ�����룬ʵ�ʵ����ӳ��ӳ��� 62.5 ��������
    szName      -- �ӳٵ���ID ����ȡ������
    ȡ������
    (void) MY.DelayCall(string szName)
    szName      -- �ӳٵ���ID
]]
MY.DelayCall = function(fnAction, nDelay, szName)
    if type(fnAction)=="function" then
        table.insert(_MY.tDelayCall, { nTime = nDelay + GetTime(), fnAction = fnAction, szName = szName })
    elseif type(fnAction)=="string" then
        for i = #_MY.tDelayCall, 1, -1 do
            if _MY.tDelayCall[i].szName == fnAction then
                table.remove(_MY.tDelayCall, i)
            end
        end
    end
end
--[[ ע�����ѭ�����ú���
    (void) MY.BreatheCall(string szKey, func fnAction[, number nTime])
    szKey		-- ���ƣ�����Ψһ���ظ��򸲸�
    fnAction	-- ѭ���������ú�������Ϊ nil ���ʾȡ����� key �µĺ���������
    nTime		-- ���ü������λ�����룬Ĭ��Ϊ 62.5����ÿ����� 16�Σ���ֵ�Զ�������� 62.5 ��������
]]
MY.BreatheCall = function(fnAction, nInterval, szName)
	szName = StringLowerW(szName)
	if type(fnAction) == "function" then
		local nFrame = 1
		if nInterval and nInterval > 0 then
			nFrame = math.ceil(nInterval / 62.5)
		end
		table.insert( _MY.tBreatheCall, { szName = szName, fnAction = fnAction, nNext = GetLogicFrameCount() + 1, nFrame = nFrame } )
	elseif type(fnAction) == "string" then
        for i = #_MY.tBreatheCall, 1, -1 do
            if _MY.tBreatheCall[i].szName == fnAction then
                table.remove(_MY.tBreatheCall, i)
            end
        end
	end
end
--[[ �ı��������Ƶ��
    (void) MY.BreatheCallDelay(string szKey, nTime)
    nTime		-- �ӳ�ʱ�䣬ÿ 62.5 �ӳ�һ֡
]]
MY.BreatheCallDelay = function(szKey, nTime)
	local t = _MY.tBreatheCall[StringLowerW(szKey)]
	if t then
		t.nFrame = math.ceil(nTime / 62.5)
		t.nNext = GetLogicFrameCount() + t.nFrame
	end
end
--[[ �ӳ�һ�κ��������ĵ���Ƶ��
    (void) MY.BreatheCallDelayOnce(string szKey, nTime)
    nTime		-- �ӳ�ʱ�䣬ÿ 62.5 �ӳ�һ֡
]]
MY.BreatheCallDelayOnce = function(szKey, nTime)
	local t = _MY.tBreatheCall[StringLowerW(szKey)]
	if t then
		t.nNext = GetLogicFrameCount() + math.ceil(nTime / 62.5)
	end
end
--[[ ע����Ϸ�¼�����
    -- ע��
    MY.RegisterEvent( szEventName, szListenerId, fnListener )
    MY.RegisterEvent( szEventName, fnListener )
    -- ע��
    MY.RegisterEvent( szEventName, szListenerId )
    MY.RegisterEvent( szEventName )
 ]]
MY.RegisterEvent = function(szEventName, arg1, arg2)
    local szListenerId, fnListener
    -- param check
    if type(szEventName)~="string" then return end
    if type(arg1)=="function" then fnListener=arg1 elseif type(arg1)=="string" then szListenerId=arg1 end
    if type(arg2)=="function" then fnListener=arg2 elseif type(arg2)=="string" then szListenerId=arg2 end
    if fnListener then -- register event
        -- ��һ�����ע��ϵͳ�¼�
        if type(_MY.tEvent[szEventName])~="table" then
            _MY.tEvent[szEventName] = {}
            RegisterEvent(szEventName, function(...)
                for i = #_MY.tEvent[szEventName], 1, -1 do
                    local hEvent = _MY.tEvent[szEventName][i]
                    if type(hEvent.fn)=="function" then
                        -- try to run event function
                        local status, err = pcall(hEvent.fn, ...)
                        -- error report
                        if not status then MY.Debug(err..'\n', 'OnEvent#'..szEventName, 2) end
                    else
                        -- remove none function event
                        table.remove(_MY.tEvent[szEventName], i)
                        -- report error
                        MY.Debug((hEvent.szName or 'id:anonymous')..' is not a function.\n', 'OnEvent#'..szEventName, 2)
                    end
                end
            end)
        end
        -- ���¼����������
        table.insert( _MY.tEvent[szEventName], { fn = fnListener, szName = szListenerId } )
    elseif szListenerId and _MY.tEvent[szEventName] then -- unregister event handle by id
        for i = #_MY.tEvent[szEventName], 1, -1 do
            if _MY.tEvent[szEventName][i].szName == fnListener then
                table.remove(_MY.tEvent[szEventName], i)
            end
        end
    elseif szEventName and _MY.tEvent[szEventName] then -- unregister all event handle
        _MY.tEvent[szEventName] = {}
    end
end
--[[ �ػ�Tab���� ]]
MY.RedrawTabPanel = function()
    local nTop = 3
    local frame = MY.GetFrame():Lookup("Window_Tabs"):GetFirstChild()
    while frame do
        local frame_d = frame
        frame = frame:GetNext()
        frame_d:Destroy()
    end
    local frame = MY.GetFrame():Lookup("Window_Main"):GetFirstChild()
    while frame do
        local frame_d = frame
        frame = frame:GetNext()
        frame_d:Destroy()
    end
    for i = 1, #_MY.tTabs, 1 do
        local tTab = _MY.tTabs[i]
        -- insert tab
        local fx = Wnd.OpenWindow(_MY.szIniFileTabBox, "aTabBox")
        if fx then    
            local item = fx:Lookup("TabBox")
            if item then
                item:ChangeRelation(MY.GetFrame():Lookup("Window_Tabs"), true, true)
                item:SetName("TabBox_" .. tTab.szName)
                item:SetRelPos(0,nTop)
                item:Lookup("","Text_TabBox_Title"):SetText(tTab.szTitle)
                item:Lookup("","Text_TabBox_Title"):SetFontColor(unpack(tTab.rgbTitleColor))
                item:Lookup("","Text_TabBox_Title"):SetAlpha(tTab.alpha)
                if tTab.dwIconFrame then
                    item:Lookup("","Image_TabBox_Icon"):FromUITex(tTab.szIconTex, tTab.dwIconFrame)
                else
                    item:Lookup("","Image_TabBox_Icon"):FromTextureFile(tTab.szIconTex)
                end
                local w,h = item:GetSize()
                nTop = nTop + h
            end
            -- register tab mouse event
            item.OnMouseEnter = function()
                this:Lookup("","Image_TabBox_Background"):Hide()
                this:Lookup("","Image_TabBox_Background_Hover"):Show()
            end
            item.OnMouseLeave = function()
                this:Lookup("","Image_TabBox_Background"):Show()
                this:Lookup("","Image_TabBox_Background_Hover"):Hide()
            end
            item.OnLButtonDown = function()
                if this:Lookup("","Image_TabBox_Background_Sel"):IsVisible() then return end
                PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
                local p = this:GetParent():GetFirstChild()
                while p do
                    p:Lookup("","Image_TabBox_Background_Sel"):Hide()
                    p = p:GetNext()
                end
                this:Lookup("","Image_TabBox_Background_Sel"):Show()
                local frame = MY.GetFrame():Lookup("Window_Main"):GetFirstChild()
                while frame do
                    if frame.fn.OnPanelDeactive then
                        local status, err = pcall(frame.fn.OnPanelDeactive, frame)
                        if not status then MY.Debug(err..'\n','MY#OnPanelDeactive',1) end
                    end
                    frame:Destroy()
                    frame = frame:GetNext()
                end
                -- insert main panel
                local fx = Wnd.OpenWindow(_MY.szIniFileMainPanel, "aMainPanel")
                local mainpanel
                if fx then    
                    mainpanel = fx:Lookup("MainPanel")
                    if mainpanel then
                        mainpanel:ChangeRelation(MY.GetFrame():Lookup("Window_Main"), true, true)
                        mainpanel:SetRelPos(0,0)
                        mainpanel.fn = tTab.fn
                    end
                end
                Wnd.CloseWindow(fx)
                if tTab.fn.OnPanelActive then
                    local status, err = pcall(tTab.fn.OnPanelActive, mainpanel)
                    if not status then MY.Debug(err..'\n','MY#OnPanelActive',1) end
                end
            end
        end
        Wnd.CloseWindow(fx)
    end
end
--[[ ע��ѡ�
    (void) MY.RegisterPanel( szName, szTitle, szIniFile, szIconTex, rgbaTitleColor, fn )
    szName          ѡ�ΨһID
    szTitle         ѡ���ť����
    szIconTex       ѡ�ͼ���ļ�|ͼ��֡
    rgbaTitleColor  ѡ�����rgba
    fn              ѡ�������Ӧ���� {
        fn.OnPanelActive(wnd)      ѡ�����    wndΪ��ǰMainPanel
        fn.OnPanelDeactive(wnd)    ѡ�ȡ������
    }
    Ex�� MY.RegisterPanel( "Test", "���Ա�ǩ", "UI/Image/UICommon/ScienceTreeNode.UITex|123", {255,255,0,200}, { OnPanelActive = function(wnd) end } )
 ]]
MY.RegisterPanel = function( szName, szTitle, szIconTex, rgbaTitleColor, fn )
    if szTitle == nil then
        for i = #_MY.tTabs, 1, -1 do
            if _MY.tTabs[i].szName == szName then
                table.remove(_MY.tTabs, i)
            end
        end
    else
        -- format szIconTex
        if type(szIconTex)~="string" then szIconTex = 'UI/Image/Common/Logo.UITex|6' end
        local dwIconFrame = string.gsub(szIconTex, '.*%|(%d+)', '%1')
        if dwIconFrame then dwIconFrame = tonumber(dwIconFrame) end
        szIconTex = string.gsub(szIconTex, '%|.*', '')
        
        -- format other params
        if type(fn)~="table" then fn = {} end
        if type(rgbaTitleColor)~="table" then rgbaTitleColor = { 255, 255, 255, 200 } end
        if type(rgbaTitleColor[1])~="number" then rgbaTitleColor[1] = 255 end
        if type(rgbaTitleColor[2])~="number" then rgbaTitleColor[2] = 255 end
        if type(rgbaTitleColor[3])~="number" then rgbaTitleColor[3] = 255 end
        if type(rgbaTitleColor[4])~="number" then rgbaTitleColor[4] = 200 end
        table.insert( _MY.tTabs, { szName = szName, szTitle = szTitle, fn = fn, szIconTex = szIconTex, dwIconFrame = dwIconFrame, rgbTitleColor = {rgbaTitleColor[1],rgbaTitleColor[2],rgbaTitleColor[3]}, alpha = rgbaTitleColor[4] } )
    end
    MY.RedrawTabPanel()
end
--[[ ����ѡ�
    (void) MY.ActivePanel( szName )
    szName          ѡ�ΨһID
]]
MY.ActivePanel = function( szName )
    local eTab = MY.GetFrame():Lookup("Window_Tabs"):Lookup('TabBox_'..szName)
    if not eTab then return end
    local _this = this
    this = eTab
    pcall(eTab.OnLButtonDown)
    this = _this
end
--[[ ע�����ͷ��˵�
    -- ע��
    (void) MY.RegisterPlayerAddonMenu(szName,Menu)
    (void) MY.RegisterPlayerAddonMenu(Menu)
    -- ע��
    (void) MY.RegisterPlayerAddonMenu(szName)
]]
MY.RegisterPlayerAddonMenu = function(arg1, arg2)
    local szName, Menu
    if type(arg1)=='string' then szName = arg1 end
    if type(arg2)=='string' then szName = arg2 end
    if type(arg1)=='table' then Menu = arg1 end
    if type(arg1)=='function' then Menu = arg1 end
    if type(arg2)=='table' then Menu = arg2 end
    if type(arg2)=='function' then Menu = arg2 end
    if Menu then
        if szName then for i = #_MY.tPlayerMenu, 1, -1 do
            if _MY.tPlayerMenu[i].szName == szName then
                _MY.tPlayerMenu[i] = {szName = szName, Menu = Menu}
                return nil
            end
        end end
        table.insert(_MY.tPlayerMenu, {szName = szName, Menu = Menu})
    elseif szName then
        for i = #_MY.tPlayerMenu, 1, -1 do
            if _MY.tPlayerMenu[i].szName == szName then
                table.remove(_MY.tPlayerMenu, i)
            end
        end
    end
end
--[[ ע��Ŀ��ͷ��˵�
    -- ע��
    (void) MY.RegisterTargetAddonMenu(szName,Menu)
    (void) MY.RegisterTargetAddonMenu(Menu)
    -- ע��
    (void) MY.RegisterTargetAddonMenu(szName)
]]
MY.RegisterTargetAddonMenu = function(arg1, arg2)
    local szName, Menu
    if type(arg1)=='string' then szName = arg1 end
    if type(arg2)=='string' then szName = arg2 end
    if type(arg1)=='table' then Menu = arg1 end
    if type(arg1)=='function' then Menu = arg1 end
    if type(arg2)=='table' then Menu = arg2 end
    if type(arg2)=='function' then Menu = arg2 end
    if Menu then
        if szName then for i = #_MY.tTargetMenu, 1, -1 do
            if _MY.tTargetMenu[i].szName == szName then
                _MY.tTargetMenu[i] = {szName = szName, Menu = Menu}
                return nil
            end
        end end
        table.insert(_MY.tTargetMenu, {szName = szName, Menu = Menu})
    elseif szName then
        for i = #_MY.tTargetMenu, 1, -1 do
            if _MY.tTargetMenu[i].szName == szName then
                table.remove(_MY.tTargetMenu, i)
            end
        end
    end
end
--[[ ע�Ṥ�����˵�
    -- ע��
    (void) MY.RegisterTraceButtonMenu(szName,Menu)
    (void) MY.RegisterTraceButtonMenu(Menu)
    -- ע��
    (void) MY.RegisterTraceButtonMenu(szName)
]]
MY.RegisterTraceButtonMenu = function(arg1, arg2)
    local szName, Menu
    if type(arg1)=='string' then szName = arg1 end
    if type(arg2)=='string' then szName = arg2 end
    if type(arg1)=='table' then Menu = arg1 end
    if type(arg1)=='function' then Menu = arg1 end
    if type(arg2)=='table' then Menu = arg2 end
    if type(arg2)=='function' then Menu = arg2 end
    if Menu then
        if szName then for i = #_MY.tTraceMenu, 1, -1 do
            if _MY.tTraceMenu[i].szName == szName then
                _MY.tTraceMenu[i] = {szName = szName, Menu = Menu}
                return nil
            end
        end end
        table.insert(_MY.tTraceMenu, {szName = szName, Menu = Menu})
    elseif szName then
        for i = #_MY.tTraceMenu, 1, -1 do
            if _MY.tTraceMenu[i].szName == szName then
                table.remove(_MY.tTraceMenu, i)
            end
        end
    end
end
-----------------------------------------------
-- ���ں���
-----------------------------------------------
-- breathe
MY.OnFrameBreathe = function()
	-- run breathe calls
	local nFrame = GetLogicFrameCount()
    for i = #_MY.tBreatheCall, 1, -1 do
        if nFrame >= _MY.tBreatheCall[i].nNext then
            _MY.tBreatheCall[i].nNext = nFrame + _MY.tBreatheCall[i].nFrame
            local res, err = pcall(_MY.tBreatheCall[i].fnAction)
            if not res then
                MY.Debug("BreatheCall#" .. (_MY.tBreatheCall[i].szName or ('anonymous_'..i)) .." ERROR: " .. err)
            elseif err == 0 then    -- function return 0 means to stop its breathe
                table.remove(_MY.tBreatheCall, i)
            end
        end
    end
    -- run delay calls
    local nTime = GetTime()
    for i = #_MY.tDelayCall, 1, -1 do
        local dc = _MY.tDelayCall[i]
        if dc.nTime <= nTime then
            local res, err = pcall(dc.fnAction)
            if not res then
                MY.Debug("DelayCall#" .. (dc.szName or 'anonymous') .." ERROR: " .. err)
            end
            table.remove(_MY.tDelayCall, i)
        end
    end
end
-- create frame
MY.OnFrameCreate = function()
end
MY.OnMouseWheel = function()
    MY.Debug(string.format('OnMouseWheel#%s.%s:%i\n',this:GetName(),this:GetType(),Station.GetMessageWheelDelta()),nil,0)
    return true
end
-- web page complete
MY.OnDocumentComplete = function()
    -- �ж��Ƿ���Զ������ȴ��ص� û����ֱ�ӷ���
    if not _MY.bRequest then return end
    -- ����ص�
    local szUrl, szTitle, szContent = this:GetLocationURL(), this:GetLocationName(), this:GetDocument()
    -- ��ȡ��������ײ�Ԫ��
    local rr = _MY.tRequest[1]
    -- �жϵ�ǰҳ���Ƿ��������
    if rr.szUrl == szUrl and ( szUrl ~= szTitle or szContent ) then
        MY.Debug(string.format("\n [RemoteRequest - OnDocumentComplete]\n [U] %s\n [T] %s\n", szUrl, szTitle),'MYRR',0)
        -- ע����ʱ����ʱ��
        MY.DelayCall("MY_Remote_Request_Timeout")
        -- �ɹ��ص�����
        pcall(rr.fnSuccess, szTitle, szContent)
        -- �������б��Ƴ�
        table.remove(_MY.tRequest, 1)
        -- ��������״̬Ϊ����
        _MY.bRequest = false
        -- ������һ��Զ������
        _MY.DoRemoteRequest()
    end
end
-- key down
MY.OnFrameKeyDown = function()
	if GetKeyName(Station.GetMessageKey()) == "Esc" then
		_MY.ClosePanel()
		return 1
	end
	return 0
end
---------------------------------------------------
---------------------------------------------------
-- �¼�����ݼ����˵�ע��
RegisterEvent("NPC_ENTER_SCENE",    function() _MY.tNearNpc[arg0]    = true end)
RegisterEvent("NPC_LEAVE_SCENE",    function() _MY.tNearNpc[arg0]    = nil  end)
RegisterEvent("PLAYER_ENTER_SCENE", function() _MY.tNearPlayer[arg0] = true end)
RegisterEvent("PLAYER_LEAVE_SCENE", function() _MY.tNearPlayer[arg0] = nil  end)
RegisterEvent("DOODAD_ENTER_SCENE", function() _MY.tNearDoodad[arg0] = true end)
RegisterEvent("DOODAD_LEAVE_SCENE", function() _MY.tNearDoodad[arg0] = nil  end)

AppendCommand("equip", MY.Equip)

TraceButton_AppendAddonMenu( { _MY.GetTraceButtonMenu } )
Player_AppendAddonMenu( { _MY.GetPlayerAddonMenu } )
Target_AppendAddonMenu( { _MY.GetTargetAddonMenu } )

if _MY.nDebugLevel <3 then RegisterEvent("CALL_LUA_ERROR", function() OutputMessage("MSG_SYS", arg0) end) end

-- MY.RegisterEvent("CUSTOM_DATA_LOADED", _MY.Init)
MY.RegisterEvent("LOADING_END", _MY.Init)
-- MY.RegisterEvent("PLAYER_ENTER_GAME", _MY.Init)
