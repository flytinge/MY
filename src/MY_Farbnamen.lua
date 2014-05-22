--
-- ���촰������Ⱦɫ���
-- By ����@˫����@ݶ����
-- ZhaiYiMing.CoM
-- 2014��5��19��05:07:02
--
local _L = MY.LoadLangPack()
---------------------------------------------------------------
-- ���ú�����
---------------------------------------------------------------
MY_Farbnamen = MY_Farbnamen or {
    bEnabled = true,
}
RegisterCustomData("Account\\MY_Farbnamen.bEnabled")
local _MY_Farbnamen = {
    szConfigPath = "PLAYER_FORCE_COLOR",
    szDataCache  = "PLAYER_INFO_CACHE\\" .. (MY.GetServer()),
    tForceColor  = {},
    tForceString = {
        [0]  = _L['JiangHu'],
        [1]  = _L['ShaoLin'],
        [2]  = _L['WanHua'],
        [3]  = _L['TianCe'],
        [4]  = _L['ChunYang'],
        [5]  = _L['QiXiu'],
        [6]  = _L['WuDu'],
        [7]  = _L['TangMen'],
        [8]  = _L['CangJian'],
        [9]  = _L['GaiBang'],
        [10] = _L['MingJiao'],
    },
    tRoleType    = {
        [1] = _L['man'],
        [2] = _L['woman'],
        [5] = _L['boy'],
        [6] = _L['girl'],
    },
    tCampString  = {
        [0] = _L['ZhongLi'],
        [1] = _L['HaoQiMeng'],
        [2] = _L['ERenGu'],
    },
    tPlayerInfo  = {},
}
setmetatable(_MY_Farbnamen.tForceString, { __index = function(t, k) return k end, __call = function(t, k, ...) return string.format(t[k], ...) end, })
setmetatable(_MY_Farbnamen.tRoleType,    { __index = function(t, k) return k end, __call = function(t, k, ...) return string.format(t[k], ...) end, })
setmetatable(_MY_Farbnamen.tCampString,  { __index = function(t, k) return k end, __call = function(t, k, ...) return string.format(t[k], ...) end, })
---------------------------------------------------------------
-- ���츴�ƺ�ʱ����ʾ���
---------------------------------------------------------------
-- �����������ݵ� HOOK �����ˡ�����ʱ�� ��
_MY_Farbnamen.AppendChatItem = function(h, szMsg)
    if MY_Farbnamen.bEnabled then
        -- change name item event binding: binding mouse in-out event
        szMsg = string.gsub(szMsg, 'eventid=515</', 'eventid=771</')
        -- get current item count
        local iPos = h:GetItemCount()
        -- normal append
        h:_AppendItemFromString_MY_Farbnamen(szMsg)
        -- if enabled
        -- color each text item
        for i = iPos, h:GetItemCount(), 1 do
            local h2 = h:Lookup(i)
            -- �ж����Item�ǲ�������Text ���������
            if h2 and h2:GetType() == "Text" and string.find(h2:GetName(), '^namelink_%d+$') then
                -- ȡ������ҵ�ID�����
                local szID = string.gsub(h2:GetName(), '%D', '')
                local dwID = tonumber(szID)
                MY_Farbnamen.AddAusID(dwID)
                -- ȡ��ҵ�����
                local szName = string.gsub(h2:GetText(), '[%[%]]', '')
                -- �������ƻ�ȡȾɫ��ɫ
                local tInfo = MY_Farbnamen.GetAusName(szName)
                -- �����ȡ�ɹ���Ⱦɫ
                if tInfo then
                    -- ���� �ȼ�
                    local szTip = string.format('%s(%d)', tInfo.szName, tInfo.nLevel)
                    -- �ƺ�
                    if tInfo.szTitle and #tInfo.szTitle > 0 then
                        szTip = string.format('%s\n%s', szTip, tInfo.szTitle)
                    end
                    -- ���
                    if tInfo.szTongID and #tInfo.szTongID > 0 then
                        szTip = string.format('%s\n[%s]', szTip, tInfo.szTongID)
                    end
                    -- ���� ���� ��Ӫ
                    local szTip = string.format('%s\n%s��%s��%s', szTip, _MY_Farbnamen.tForceString[tInfo.dwForceID], _MY_Farbnamen.tRoleType[tInfo.nRoleType], _MY_Farbnamen.tCampString[tInfo.nCamp])
                    -- ��tip��ʾ
                    MY.UI(h2):tip(szTip, MY.Const.UI.Tip.POS_TOP):color(tInfo.rgb)
                end
            end
        end
    else
        -- normal append
        h:_AppendItemFromString_MY_Farbnamen(szMsg)
    end
end

-- chat time/copy
_MY_Farbnamen.OnChatPanelInit = function()
	for i = 1, 10 do
		local h = Station.Lookup("Lowest2/ChatPanel" .. i .. "/Wnd_Message", "Handle_Message")
		local ttl = Station.Lookup("Lowest2/ChatPanel" .. i .. "/CheckBox_Title", "Text_TitleName")
		if h and (not ttl or ttl:GetText() ~= g_tStrings.CHANNEL_MENTOR) then
			h._AppendItemFromString_MY_Farbnamen = h._AppendItemFromString_MY_Farbnamen or h.AppendItemFromString
			h.AppendItemFromString = _MY_Farbnamen.AppendChatItem
		end
	end
end
MY_Farbnamen.OnChatPanelInit = _MY_Farbnamen.OnChatPanelInit
-- ��������ͻ
function MY_Farbnamen.DoConflict()
    if MY_Farbnamen.bEnabled and Chat and Chat.bColor then
        Chat.bColor = false
        MY.Sysmsg({_L['plugin conflict detected,duowan force color has been forced down.'], r=255, g=0, b=0},_L['MingYiPlugin - Farbnamen'])
    end
end
---------------------------------------------------------------
-- ���ݴ洢
---------------------------------------------------------------
-- ͨ��szName��ȡ��Ϣ
function MY_Farbnamen.GetAusName(szName)
    return MY_Farbnamen.GetAusID(_MY_Farbnamen.tPlayerInfo[szName])
end
-- ͨ��dwID��ȡ��Ϣ
function MY_Farbnamen.GetAusID(dwID)
    MY_Farbnamen.AddAusID(dwID)
    -- deal with return data
    local result =  clone(_MY_Farbnamen.tPlayerInfo[dwID])
    if result then
        result.rgb = _MY_Farbnamen.tForceColor[result.dwForceID]
    end
    return result
end
-- ����ָ��dwID�����
function MY_Farbnamen.AddAusID(dwID)
    local player = GetPlayer(dwID)
    if player and player.szName and player.szName~='' then
        _MY_Farbnamen.tPlayerInfo[player.dwID  ] = {
            dwForceID = player.dwForceID,
            szName    = player.szName,
            nRoleType = player.nRoleType,
            nLevel    = player.nLevel,
            szTitle   = player.szTitle,
            nCamp     = player.nCamp,
            szTongID  = GetTongClient().ApplyGetTongName(player.dwTongID),
        }
        _MY_Farbnamen.tPlayerInfo[player.szName] = player.dwID
    end
end

-- ��������
function MY_Farbnamen.SaveData()
    MY.SaveLUAData(_MY_Farbnamen.szDataCache, _MY_Farbnamen.tPlayerInfo)
end
-- ��������
function MY_Farbnamen.LoadData()
    local data = MY.LoadLUAData(_MY_Farbnamen.szConfigPath, '') or {}
    _MY_Farbnamen.tForceColor   = data  or _MY_Farbnamen.tForceColor
    _MY_Farbnamen.tPlayerInfo = MY.LoadLUAData(_MY_Farbnamen.szDataCache) or _MY_Farbnamen.tPlayerInfo
end
--------------------------------------------------------------
-- ����ͳ��
--------------------------------------------------------------
function MY_Farbnamen.AnalyseForceInfo()
	local t = { }
    -- ͳ�Ƹ���������
	for k, v in pairs(_MY_Farbnamen.tPlayerInfo) do
		if type(v)=='table' and type(v.dwForceID)=='number' then
			t[v.dwForceID] = ( t[v.dwForceID] or 0 ) + 1
		end
	end
	-- ��tableֵ��������
	local t2, nCount = {}, 0
	for k, v in pairs(t) do
		table.insert(t2, {K = k, V = v})
        nCount = nCount + v
	end
	table.sort (t2, function(a, b) return a.V > b.V end)

    -- ���
	MY.Sysmsg({_L('%d player(s) data cached:', nCount)}, _L['Farbnamen'])
	for k, v in pairs(t2) do
		if type(v.K) == "number" then
			MY.Sysmsg({string.format("%s\t(%s)\t%d", GetForceTitle(v.K), string.format("%02d%%", 100 * (v.V / nCount)), v.V)}, '')
		end
	end
end

--------------------------------------------------------------
-- �˵�
--------------------------------------------------------------
MY_Farbnamen.GetMenu = function()
    return { 
        szOption = _L["Farbnamen"],
        fnAction = function()
            MY_Farbnamen.bEnabled = not MY_Farbnamen.bEnabled
        end,
        bCheck = true,
        bChecked = MY_Farbnamen.bEnabled, {
            szOption = _L["analyse data"],
            fnAction = MY_Farbnamen.AnalyseForceInfo,
        }, {
            szOption = _L["reset data"],
            fnAction = function()
                _MY_Farbnamen.tPlayerInfo = {}
                MY.Sysmsg({_L['cache data deleted.']}, _L['Farbnamen'])
            end,
        }
    }
end
MY.RegisterPlayerAddonMenu( 'MY_Farbenamen', MY_Farbnamen.GetMenu )
MY.RegisterTraceButtonMenu( 'MY_Farbenamen', MY_Farbnamen.GetMenu )
--------------------------------------------------------------
-- ע���¼�
--------------------------------------------------------------
MY.RegisterEvent("CHAT_PANEL_INIT", _MY_Farbnamen.OnChatPanelInit)
MY.RegisterEvent('LOGIN_GAME', MY_Farbnamen.LoadData)
MY.RegisterEvent('PLAYER_ENTER_GAME', MY_Farbnamen.LoadData)
MY.RegisterEvent('GAME_EXIT', MY_Farbnamen.SaveData)
MY.RegisterEvent('PLAYER_EXIT_GAME', MY_Farbnamen.SaveData)
MY.RegisterEvent("PLAYER_ENTER_SCENE", MY_Farbnamen.DoConflict)
MY.RegisterEvent("PLAYER_ENTER_SCENE", function(...)
    if MY_Farbnamen.bEnabled then
        local dwID = arg0
        MY.DelayCall( function() MY_Farbnamen.AddAusID(dwID) end, 500 )
    end
end)