local _L = MY.LoadLangPack()
MY_RollMonitor = { nMode = 1, nPublish = 0, nPublishChannel = PLAYER_TALK_CHANNEL.RAID, bPublishRestart = true }
RegisterCustomData('MY_RollMonitor.nMode')
RegisterCustomData('MY_RollMonitor.nPublish')
RegisterCustomData('MY_RollMonitor.bPublishRestart')
RegisterCustomData('MY_RollMonitor.nPublishChannel')
local _MY_RollMonitor = {
    bInvalidRectangle = false,
    uiTextBoard = nil,
    aRecords = {},
    aMode = {
        [1] = { szID = 'nFirst', szName = _L['only first score'           ] },    -- ֻ��¼��һ��
        [2] = { szID = 'nLast' , szName = _L['only last score'            ] },    -- ֻ��¼���һ��
        [3] = { szID = 'nMax'  , szName = _L['highest score'              ] },    -- ���ҡ��ȡ��ߵ�
        [4] = { szID = 'nMin'  , szName = _L['lowest score'               ] },    -- ���ҡ��ȡ��͵�
        [5] = { szID = 'nAvg'  , szName = _L['average score'              ] },    -- ���ҡ��ȡƽ��ֵ
        [6] = { szID = 'nAvg2' , szName = _L['average score with out pole'] },    -- ȥ��������ȡƽ��ֵ
    },
    tChannels = {
        { nChannel = PLAYER_TALK_CHANNEL.NEARBY, szName = _L['nearby channel'], rgb = GetMsgFontColor("MSG_NORMAL", true) },
        { nChannel = PLAYER_TALK_CHANNEL.TEAM  , szName = _L['team channel']  , rgb = GetMsgFontColor("MSG_TEAM"  , true) },
        { nChannel = PLAYER_TALK_CHANNEL.RAID  , szName = _L['raid channel']  , rgb = GetMsgFontColor("MSG_TEAM"  , true) },
        { nChannel = PLAYER_TALK_CHANNEL.TONG  , szName = _L['tong channel']  , rgb = GetMsgFontColor("MSG_GUILD" , true) },
    }
}
-- ��ǩ������Ӧ����
_MY_RollMonitor.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    -- ��¼ģʽ
    ui:append('WndCombo_RecordType','WndComboBox'):child('#WndCombo_RecordType'):text(_MY_RollMonitor.aMode[MY_RollMonitor.nMode].szName):pos(20,20):width(180):menu(function()
        local t = {}
        for iMode, tMode in ipairs(_MY_RollMonitor.aMode) do
            table.insert( t, { 
                szOption = tMode.szName,
                fnAction = function()
                    MY_RollMonitor.nMode, _MY_RollMonitor.bInvalidRectangle = iMode, true
                    table.sort(_MY_RollMonitor.aRecords,function(v1,v2)return v1[tMode.szID] > v2[tMode.szID] end)
                    ui:child('#WndCombo_RecordType'):text(tMode.szName)
                end
            } )
        end
        return t
    end)
    -- ���
    ui:append('WndButton_Clear','WndButton'):child('#WndButton_Clear'):text(_L['restart']):pos(450,20):width(90):lclick(function(nButton)
        _MY_RollMonitor.aRecords, _MY_RollMonitor.bInvalidRectangle = {}, true
        if MY_RollMonitor.bPublishRestart then
            MY.Talk(MY_RollMonitor.nPublishChannel, _L['--------------- roll restart ----------------']..'\n')
        end
    end):rmenu(function()
        local t = { {
            szOption = _L['publish setting'], 
            bCheck = true, bMCheck = false, bChecked = MY_RollMonitor.bPublishRestart,
            fnAction = function() MY_RollMonitor.bPublishRestart = not MY_RollMonitor.bPublishRestart end,
        }, { bDevide = true } }
        for _, tChannel in ipairs(_MY_RollMonitor.tChannels) do
            table.insert( t, { 
                szOption = tChannel.szName,
                rgb = tChannel.rgb,
                bCheck = true, bMCheck = true, bChecked = MY_RollMonitor.nPublishChannel == tChannel.nChannel,
                fnAction = function()
                    MY_RollMonitor.nPublishChannel = tChannel.nChannel
                end
            } )
        end
        return t
    end):tip(_L['left click to restart, right click to open setting.'], MY.Const.UI.Tip.POS_TOP)
    -- ����
    ui:append('WndButton_Publish','WndButton'):child('#WndButton_Publish'):text(_L['publish']):pos(540,20):width(80):rmenu(function()
        local t = { {
            szOption = _L['publish setting'], {
                bCheck = true, bMCheck = true, bChecked = MY_RollMonitor.nPublish == 3,
                fnAction = function() MY_RollMonitor.nPublish = 3 end,
                szOption = _L('publish top %d', 3)
            }, {
                bCheck = true, bMCheck = true, bChecked = MY_RollMonitor.nPublish == 5,
                fnAction = function() MY_RollMonitor.nPublish = 5 end,
                szOption = _L('publish top %d', 5)
            }, {
                bCheck = true, bMCheck = true, bChecked = MY_RollMonitor.nPublish == 10,
                fnAction = function() MY_RollMonitor.nPublish = 10 end,
                szOption = _L('publish top %d', 10)
            }, {
                bCheck = true, bMCheck = true, bChecked = MY_RollMonitor.nPublish == 0,
                fnAction = function() MY_RollMonitor.nPublish = 0 end,
                szOption = _L['publish all']
            }
        }, { bDevide = true } }
        for _, tChannel in ipairs(_MY_RollMonitor.tChannels) do
            table.insert( t, { 
                szOption = tChannel.szName,
                rgb = tChannel.rgb,
                bCheck = true, bMCheck = true, bChecked = MY_RollMonitor.nPublishChannel == tChannel.nChannel,
                fnAction = function()
                    MY_RollMonitor.nPublishChannel = tChannel.nChannel
                end
            } )
        end
        return t
    end):lclick(function()
        MY.Talk(MY_RollMonitor.nPublishChannel, string.format('[%s][%s]%s\n',_L['mingyi plugin'],_L["roll monitor"],_MY_RollMonitor.aMode[MY_RollMonitor.nMode].szName), true)
        MY.Talk(MY_RollMonitor.nPublishChannel, _L['---------------------------------------------']..'\n')
        for i, aRecord in ipairs(_MY_RollMonitor.aRecords) do
            if MY_RollMonitor.nPublish > 0 and i > MY_RollMonitor.nPublish then break end
            MY.Talk(MY_RollMonitor.nPublishChannel, _L( '[%s] rolls for %d times, valid score is %s.', aRecord.szName, #aRecord, (string.gsub(aRecord[_MY_RollMonitor.aMode[MY_RollMonitor.nMode].szID],'(%d+%.%d%d)%d+','%1')) ) .. '\n')
        end
        local team = GetClientTeam()
        if team then
            local szUnrolledNames = ''
            for _, dwID in ipairs(team.GetTeamMemberList()) do
                local szName, bUnRoll = team.GetClientTeamMemberName(dwID), true
                for _, aRecord in ipairs(_MY_RollMonitor.aRecords) do
                    if aRecord.szName == szName then
                        bUnRoll = false
                    end
                end
                if bUnRoll then szUnrolledNames = szUnrolledNames .. '[' .. szName .. ']' end
            end
            if szUnrolledNames~='' then
                MY.Talk(MY_RollMonitor.nPublishChannel, szUnrolledNames .. _L["haven't roll yet."]..'\n')
            end
        end
        MY.Talk(MY_RollMonitor.nPublishChannel, _L['---------------------------------------------']..'\n')
    end):tip(_L['left click to publish, right click to open setting.'], MY.Const.UI.Tip.POS_TOP, { x = -80 })
    -- �����
    ui:append('WndScrollBox_Record','WndScrollBox'):child('#WndScrollBox_Record'):handleStyle(3):pos(20,50):size(600,400):text(_L['ȥ��������ȡƽ��ֵ']):append('Text_Default','Text'):children('#Text_Default')
    _MY_RollMonitor.uiBoard = ui:child('#WndScrollBox_Record')
    -- ֱ����RegisterMonitor�������UI��������ReloadUIAddon֮���񱨴� �����ҿ���һ����ʱ��ˢ�½���
    MY.BreatheCall('MY_RollMonitorRedraw',100,function()
        if _MY_RollMonitor.bInvalidRectangle then
            _MY_RollMonitor.bInvalidRectangle = false
            _MY_RollMonitor.RedrawBoard()
        end
    end)
    _MY_RollMonitor.RedrawBoard()
end
_MY_RollMonitor.OnPanelDeactive = function()
    MY.BreatheCall('MY_RollMonitorRedraw')
    _MY_RollMonitor.uiBoard = nil
end
-- �ػ洰��
_MY_RollMonitor.RedrawBoard = function()
    if _MY_RollMonitor.uiBoard then
        local szText = ''
        for _, aRecord in ipairs(_MY_RollMonitor.aRecords) do
            szText = szText .. _L( '[%s] rolls for %d times, valid score is %s.', aRecord.szName, #aRecord, (string.gsub(aRecord[_MY_RollMonitor.aMode[MY_RollMonitor.nMode].szID],'(%d+%.%d%d)%d+','%1')) ) .. '\n'
        end
        local team = GetClientTeam()
        if team then
            local szUnrolledNames = ''
            for _, dwID in ipairs(team.GetTeamMemberList()) do
                local szName, bUnRoll = team.GetClientTeamMemberName(dwID), true
                for _, aRecord in ipairs(_MY_RollMonitor.aRecords) do
                    if aRecord.szName == szName then
                        bUnRoll = false
                    end
                end
                if bUnRoll then szUnrolledNames = szUnrolledNames .. '[' .. szName .. ']' end
            end
            if szUnrolledNames~='' then szUnrolledNames = szUnrolledNames .. _L["haven't roll yet."] end
            szText = szText .. szUnrolledNames
        end
        _MY_RollMonitor.uiBoard:text(szText)
    end
end
-- ϵͳƵ����ش�����
_MY_RollMonitor.OnMsgArrive = function(szMsg, nFont, bRich, r, g, b)
    for szName, nRoll in string.gmatch(szMsg, _L['ROLL_MONITOR_EXP'] ) do
        -- ��ʱ����
        nRoll = tonumber(nRoll)
        local nTotal, nAvg, nAvg2 = 0
        -- ��ǰҪ���ɵ�һ����ҵļ�¼
        local aRecord = {
            szName = szName,
            nFirst = nRoll,
            nMax =   nRoll,
            nMin =   nRoll,
        }
        -- �жϻ����и�����Ƿ��Ѵ��ڼ�¼
        for i = 1, #_MY_RollMonitor.aRecords, 1 do
            if _MY_RollMonitor.aRecords[i].szName == szName then
                aRecord = _MY_RollMonitor.aRecords[i]
                break
            end
        end
        -- ��ʽ������ ���¸���ֵ
        table.insert(aRecord, nRoll)
        table.sort(aRecord)
        local nTotal = 0
        for i = 1, #aRecord, 1 do
            nTotal = nTotal + aRecord[i]
        end
        aRecord.nAvg = nTotal / #aRecord
        if #aRecord > 2 then
            aRecord.nAvg2 = (nTotal - aRecord[1] - aRecord[#aRecord]) / (#aRecord - 2)
        else
            aRecord.nAvg2 = aRecord.nAvg
        end
        aRecord.nLast = nRoll
        if aRecord.nMax < nRoll then aRecord.nMax = nRoll end
        if aRecord.nMin > nRoll then aRecord.nMin = nRoll end
        -- ������д�ؼ�¼����
        for i = #_MY_RollMonitor.aRecords, 1, -1 do
            if _MY_RollMonitor.aRecords[i].szName == szName then
                table.remove(_MY_RollMonitor.aRecords, i)
            end
        end
        table.insert(_MY_RollMonitor.aRecords, aRecord)
        table.sort(_MY_RollMonitor.aRecords,function(v1,v2)return v1[_MY_RollMonitor.aMode[MY_RollMonitor.nMode].szID] > v2[_MY_RollMonitor.aMode[MY_RollMonitor.nMode].szID] end)
        _MY_RollMonitor.bInvalidRectangle = true
    end
end
-- ע��ϵͳƵ�����
_MY_RollMonitor.RegisterMsgMonitor = function()
    local t = {'MSG_SYS'}
    UnRegisterMsgMonitor(_MY_RollMonitor.OnMsgArrive)
    RegisterMsgMonitor(_MY_RollMonitor.OnMsgArrive, t)
end
_MY_RollMonitor.RegisterMsgMonitor()
MY.RegisterPanel( "RollMonitor", _L["roll monitor"], "UI/Image/UICommon/LoginCommon.UITex|30", {255,255,0,200}, { OnPanelActive = _MY_RollMonitor.OnPanelActive, OnPanelDeactive = _MY_RollMonitor.OnPanelDeactive } )