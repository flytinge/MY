-----------------------------------------------
-- @Desc  : ��ɫС����
-- @Author: ���� @tinymins
-- @Date  : 2014-11-25 12:31:03
-- @Email : admin@derzh.com
-- @Last modified by:   tinymins
-- @Last modified time: 2016-12-13 15:23:48
-----------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_Toolbox/lang/")
local _C = {}
local PUBLIC_PLAYER_NOTES = {} -- �����������
local PRIVATE_PLAYER_NOTES = {} -- ˽���������
MY_Anmerkungen = MY_Anmerkungen or {}
-- dwID : { dwID = dwID, szName = szName, szContent = szContent, bAlertWhenGroup, bTipWhenGroup }

-- ��һ����ҵļ�¼�༭��
function MY_Anmerkungen.OpenPlayerNoteEditPanel(dwID, szName)
	local note = MY_Anmerkungen.GetPlayerNote(dwID) or {}
	-- frame
	local ui = MY.UI.CreateFrame("MY_Anmerkungen_PlayerNoteEdit_"..(dwID or 0))
	local CloseFrame = function()
		ui:remove()
		return true
	end

	MY.RegisterEsc('MY_Anmerkungen_PlayerNoteEditPanel', function()
		return ui and ui:count() > 0
	end, CloseFrame)
	local function onRemove()
		MY.RegisterEsc('MY_Anmerkungen_PlayerNoteEditPanel')
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
	ui:remove(onRemove)

	local w, h = 300, 210
	local x, y = 35 , 50

	ui:size(w + 40, h + 90):anchor( { s = "CENTER", r = "CENTER", x = 0, y = 0 } )
	-- title
	ui:text(_L['my anmerkungen - player note edit'])
	-- id
	ui:append("Text", "Label_ID"):children("#Label_ID"):pos(x, y)
	  :text(_L['ID:'])
	-- id input
	ui:append("WndEditBox", "WndEditBox_ID"):children("#WndEditBox_ID"):pos(x + 60, y)
	  :size(200, 25):multiLine(false):enable(false):color(200,200,200)
	  :text(dwID or note.dwID or "")
	-- name
	ui:append("Text", "Label_Name"):children("#Label_Name"):pos(x, y + 30)
	  :text(_L['Name:'])
	-- name input
	ui:append("WndEditBox", "WndEditBox_Name"):children("#WndEditBox_Name"):pos(x + 60, y + 30)
	  :size(200, 25):multiLine(false):text(szName or note.szName or "")
	  :change(function(szName)
	  	local rec = MY_Anmerkungen.GetPlayerNote(szName)
	  	if rec then
	  		ui:children("#WndButton_Submit"):enable(true)
	  		ui:children("#WndEditBox_ID"):text(rec.dwID)
	  		ui:children("#WndEditBox_Content"):text(rec.szContent)
	  		ui:children("#WndCheckBox_TipWhenGroup"):check(rec.bTipWhenGroup)
	  		ui:children("#WndCheckBox_AlertWhenGroup"):check(rec.bAlertWhenGroup)
	  	else
	  		local tInfo
	  		if MY_Farbnamen then
	  			tInfo = MY_Farbnamen.GetAusName(szName)
	  		end
	  		if tInfo then
	  			ui:children("#WndButton_Submit"):enable(true)
	  			ui:children("#WndEditBox_ID"):text(tInfo.dwID)
	  			ui:children("#WndEditBox_Content"):text('')
	  			ui:children("#WndCheckBox_TipWhenGroup"):check(true)
	  			ui:children("#WndCheckBox_AlertWhenGroup"):check(false)
	  		else
	  			ui:children("#WndButton_Submit"):enable(false)
	  			ui:children("#WndEditBox_ID"):text('')
	  		end
	  	end
	  end)
	-- content
	ui:append("Text", "Label_Content"):children("#Label_Content"):pos(x, y + 60)
	  :text(_L['Content:'])
	-- content input
	ui:append("WndEditBox", "WndEditBox_Content"):children("#WndEditBox_Content")
	  :pos(x + 60, y + 60):size(200, 80)
	  :multiLine(true):text(note.szContent or "")
	-- alert when group
	ui:append("WndCheckBox", "WndCheckBox_AlertWhenGroup"):children("#WndCheckBox_AlertWhenGroup")
	  :pos(x + 58, y + 140):width(200)
	  :text(_L['alert when group']):check(note.bAlertWhenGroup or false)
	-- tip when group
	ui:append("WndCheckBox", "WndCheckBox_TipWhenGroup"):children("#WndCheckBox_TipWhenGroup")
	  :pos(x + 58, y + 160):width(200)
	  :text(_L['tip when group']):check(note.bTipWhenGroup or true)
	-- submit button
	ui:append("WndButton", "WndButton_Submit"):children("#WndButton_Submit")
	  :pos(x + 58, y + 190):width(80)
	  :text(_L['sure']):click(function()
	  	MY_Anmerkungen.SetPlayerNote(
	  		ui:children("#WndEditBox_ID"):text(),
	  		ui:children("#WndEditBox_Name"):text(),
	  		ui:children("#WndEditBox_Content"):text(),
	  		ui:children("#WndCheckBox_TipWhenGroup"):check(),
	  		ui:children("#WndCheckBox_AlertWhenGroup"):check()
	  	)
	  	CloseFrame(ui)
	  end)
	-- cancel button
	ui:append("WndButton", "WndButton_Cancel"):children("#WndButton_Cancel")
	  :pos(x + 143, y + 190):width(80)
	  :text(_L['cancel']):click(function() CloseFrame(ui) end)
	-- delete button
	ui:append("Text", "Text_Delete"):children("#Text_Delete")
	  :pos(x + 230, y + 188):width(80):alpha(200)
	  :text(_L['delete']):color(255,0,0):hover(function(bIn) MY.UI(this):alpha((bIn and 255) or 200) end)
	  :click(function()
	  	MY_Anmerkungen.SetPlayerNote(ui:children("#WndEditBox_ID"):text())
	  	CloseFrame(ui)
	  	-- ɾ��
	  end)

	-- init data
	ui:children("#WndEditBox_Name"):change()
	Station.SetFocusWindow(ui[1])
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end
-- �����Ҽ��˵�
MY.RegisterTargetAddonMenu("MY_Anmerkungen_PlayerNotes", function()
	local dwType, dwID = MY.GetTarget()
	if dwType == TARGET.PLAYER then
		local p = MY.GetObject(dwType, dwID)
		return {
			szOption = _L['edit player note'],
			fnAction = function()
				MY.DelayCall(1, function()
					MY_Anmerkungen.OpenPlayerNoteEditPanel(p.dwID, p.szName)
				end)
			end
		}
	end
end)

do
local menu = {
	szOption = _L["Create new anmerkungen"],
	fnAction = function() MY_Anmerkungen.OpenPlayerNoteEditPanel() end,
}
MY.RegisterAddonMenu("MY_Anmerkungen_PlayerNotes", menu)
end
-- ��ȡһ����ҵļ�¼
function MY_Anmerkungen.GetPlayerNote(dwID)
	-- { dwID, szName, szContent, bTipWhenGroup, bAlertWhenGroup, bPrivate }
	dwID = tostring(dwID)
	local t, rec = {}, nil
	if not rec then
		rec = PRIVATE_PLAYER_NOTES[dwID]
		if type(rec) ~= "table" then
			rec = PRIVATE_PLAYER_NOTES[tostring(rec)]
		end
		t.bPrivate = true
	end
	if not rec then
		rec = PUBLIC_PLAYER_NOTES[dwID]
		if type(rec) ~= "table" then
			rec = PUBLIC_PLAYER_NOTES[tostring(rec)]
		end
		t.bPrivate = false
	end
	if not rec then
		t = nil
	else
		t.dwID, t.szName, t.szContent, t,bTipWhenGroup, t.bAlertWhenGroup = rec.dwID, rec.szName, rec.szContent, rec,bTipWhenGroup, rec.bAlertWhenGroup
	end
	return t
end
-- ������ҽ���ʱ
function MY_Anmerkungen.OnPartyAddMember()
	MY_Anmerkungen.PartyAddMember(arg1)
end
function MY_Anmerkungen.PartyAddMember(dwID)
	local team = GetClientTeam()
	local szName = team.GetClientTeamMemberName(dwID)
	-- local dwLeaderID = team.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER)
	-- local szLeaderName = team.GetClientTeamMemberName(dwLeader)
	local t = MY_Anmerkungen.GetPlayerNote(dwID)
	if t then
		if t.bAlertWhenGroup then
			MessageBox({
				szName = "MY_Anmerkungen_PlayerNotes_"..t.dwID,
				szMessage = _L("Tip: [%s] is in your team.\nNote: %s\n", t.szName, t.szContent),
				{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() end},
			})
		end
		if t.bTipWhenGroup then
			MY.Sysmsg({_L("Tip: [%s] is in your team.\nNote: %s", t.szName, t.szContent)})
		end
	end
end
MY.RegisterEvent("PARTY_ADD_MEMBER", MY_Anmerkungen.OnPartyAddMember)
MY.RegisterEvent("PARTY_SYNC_MEMBER_DATA", MY_Anmerkungen.OnPartyAddMember)
-- ����һ����ҵļ�¼
function MY_Anmerkungen.SetPlayerNote(dwID, szName, szContent, bTipWhenGroup, bAlertWhenGroup, bPrivate)
	if not dwID then return nil end
	dwID = tostring(dwID)
	if not szName then -- ɾ��һ����ҵļ�¼
		MY_Anmerkungen.LoadConfig()
		if PRIVATE_PLAYER_NOTES[dwID] then
			PRIVATE_PLAYER_NOTES[PRIVATE_PLAYER_NOTES[dwID].szName] = nil
			PRIVATE_PLAYER_NOTES[dwID] = nil
		end
		if PUBLIC_PLAYER_NOTES[dwID] then
			PUBLIC_PLAYER_NOTES[PUBLIC_PLAYER_NOTES[dwID].szName] = nil
			PUBLIC_PLAYER_NOTES[dwID] = nil
		end
		if _C.list then
			_C.list:listbox('delete', 'id', dwID)
		end
		MY_Anmerkungen.SaveConfig()
		return nil
	end
	MY_Anmerkungen.SetPlayerNote(dwID)
	MY_Anmerkungen.LoadConfig()
	local t = {
		dwID = dwID,
		szName = szName,
		szContent = szContent,
		bTipWhenGroup = bTipWhenGroup,
		bAlertWhenGroup = bAlertWhenGroup,
	}
	if bPrivate then
		PRIVATE_PLAYER_NOTES[dwID] = t
		PRIVATE_PLAYER_NOTES[szName] = dwID
	else
		PUBLIC_PLAYER_NOTES[dwID] = t
		PUBLIC_PLAYER_NOTES[szName] = dwID
	end
	if _C.list then
		_C.list:listbox('update', 'id', dwID, {"text", "data"}, { _L('[%s] %s', t.szName, t.szContent), t })
	end
	MY_Anmerkungen.SaveConfig()
end
-- ��ȡ��������
function MY_Anmerkungen.LoadConfig()
	local szOrgFile = MY.GetLUADataPath("config/PLAYER_NOTES/$relserver.$lang.jx3dat")
	local szFilePath = MY.GetLUADataPath({"config/playernotes.jx3dat", MY_DATA_PATH.SERVER})
	if IsLocalFileExist(szOrgFile) then
		CPath.Move(szOrgFile, szFilePath)
	end
	PUBLIC_PLAYER_NOTES = MY.LoadLUAData(szFilePath) or {}
	if type(PUBLIC_PLAYER_NOTES) == 'string' then
		PUBLIC_PLAYER_NOTES = MY.Json.Decode(PUBLIC_PLAYER_NOTES)
	end

	local szOrgFile = MY.GetLUADataPath("config/PLAYER_NOTES/$uid.$lang.jx3dat")
	local szFilePath = MY.GetLUADataPath({"config/playernotes.jx3dat", MY_DATA_PATH.ROLE})
	if IsLocalFileExist(szOrgFile) then
		CPath.Move(szOrgFile, szFilePath)
	end
	PRIVATE_PLAYER_NOTES = MY.LoadLUAData(szFilePath) or {}
	if type(PRIVATE_PLAYER_NOTES) == 'string' then
		PRIVATE_PLAYER_NOTES = MY.Json.Decode(PRIVATE_PLAYER_NOTES)
	end
end
-- ���湫������
function MY_Anmerkungen.SaveConfig()
	MY.SaveLUAData({"config/playernotes.jx3dat", MY_DATA_PATH.SERVER}, PUBLIC_PLAYER_NOTES)
	MY.SaveLUAData({"config/playernotes.jx3dat", MY_DATA_PATH.ROLE}, PRIVATE_PLAYER_NOTES)
end
MY.RegisterInit('MY_ANMERKUNGEN', MY_Anmerkungen.LoadConfig)

local PS = {}
function PS.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local x, y = 0, 0

	ui:append("WndButton2", {
		x = x, y = y, w = 110,
		text = _L['Create'],
		onclick = function()
			MY_Anmerkungen.OpenPlayerNoteEditPanel()
		end,
	})

	ui:append("WndButton2", {
		x = w - 230, y = y, w = 110,
		text = _L['Import'],
		onclick = function()
			GetUserInput(_L['please input import data:'], function(szVal)
				local config = str2var(szVal)
				if config and config.server and config.public and config.private then
					if config.server ~= MY.GetRealServer() then
						return MY.Alert(_L['Server not match!'])
					end
					local function Next(usenew)
						for k, v in pairs(config.public) do
							if not PUBLIC_PLAYER_NOTES[k] or usenew then
								PUBLIC_PLAYER_NOTES[k] = v
							end
						end
						for k, v in pairs(config.private) do
							if not PRIVATE_PLAYER_NOTES[k] or usenew then
								PRIVATE_PLAYER_NOTES[k] = v
							end
						end
						MY_Anmerkungen.SaveConfig()
						MY.SwitchTab("MY_Anmerkungen_Player_Note", true)
					end
					MY.Confirm(_L['Prefer old data or new data?'], function() Next(false) end,
						function() Next(true) end, _L['Old data'], _L['New data'])
				else
					MY.Alert(_L['Decode data failed!'])
				end
			end, function() end, function() end, nil, "" )
		end,
	})

	ui:append("WndButton2", {
		x = w - 110, y = y, w = 110,
		text = _L['Export'],
		onclick = function()
			XGUI.OpenTextEditor(var2str({
				server  = MY.GetRealServer(),
				public  = PUBLIC_PLAYER_NOTES,
				private = PRIVATE_PLAYER_NOTES,
			}))
		end,
	})

	y = y + 30
	local list = ui:append("WndListBox", "WndListBox_1"):children('#WndListBox_1')
	  :pos(x, y)
	  :size(w, h - 30)
	  :listbox('onlclick', function(hItem, szText, szID, data, bSelected)
	  	MY_Anmerkungen.OpenPlayerNoteEditPanel(data.dwID, data.szName)
	  	return false
	  end)
	for dwID, t in pairs(PUBLIC_PLAYER_NOTES) do
		if tonumber(dwID) then
			list:listbox('insert', _L('[%s] %s', t.szName, t.szContent), t.dwID, t)
		end
	end
	_C.list = list
end
function PS.OnPanelDeactive()
	_C.list = nil
end
MY.RegisterPanel( "MY_Anmerkungen_Player_Note", _L["player note"], _L['Target'], "ui/Image/button/ShopButton.UITex|12", {255,255,0,200}, PS)
