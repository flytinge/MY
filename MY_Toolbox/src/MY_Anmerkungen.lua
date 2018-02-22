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
local PUBLIC_PLAYER_IDS = {}
local PUBLIC_PLAYER_NOTES = {}
local PRIVATE_PLAYER_IDS = {}
local PRIVATE_PLAYER_NOTES = {}
MY_Anmerkungen = MY_Anmerkungen or {}
-- dwID : { dwID = dwID, szName = szName, szContent = szContent, bAlertWhenGroup, bTipWhenGroup }

-- ��һ����ҵļ�¼�༭��
function MY_Anmerkungen.OpenPlayerNoteEditPanel(dwID, szName)
	if not MY_Farbnamen then
		return MY.Alert(_L['MY_Farbnamen not detected! Please check addon load!'])
	end
	local note = MY_Anmerkungen.GetPlayerNote(dwID) or {}

	local w, h = 340, 300
	local ui = MY.UI.CreateFrame("MY_Anmerkungen_PlayerNoteEdit_" .. (dwID or 0), {
		w = w, h = h, anchor = {},
		text = _L['my anmerkungen - player note edit'],
	})

	local function IsValid()
		return ui and ui:count() > 0
	end
	local function RemoveFrame()
		ui:remove()
		return true
	end
	MY.RegisterEsc('MY_Anmerkungen_PlayerNoteEditPanel', IsValid, RemoveFrame)

	local function onRemove()
		MY.RegisterEsc('MY_Anmerkungen_PlayerNoteEditPanel')
		PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
	end
	ui:remove(onRemove)

	local x, y = 35 , 50
	ui:append("Text", { x = x, y = y, text = _L['ID:'] })
	ui:append("WndEditBox", {
		name = "WndEditBox_ID", x = x + 60, y = y, w = 200, h = 25,
		text = dwID or note.dwID or "",
		multiline = false, enable = false, color = {200,200,200},
	})
	y = y + 30

	ui:append("Text", { x = x, y = y, text = _L['Name:'] })
	ui:append("WndEditBox", {
		name = "WndEditBox_Name",
		x = x + 60, y = y, w = 200, h = 25,
		multiline = false, text = szName or note.szName or "",
		onchange = function(szName)
			local rec = MY_Anmerkungen.GetPlayerNote(szName) or {}
			local info = MY_Farbnamen.GetAusName(szName)
			if info and rec.dwID ~= info.dwID then
				rec.dwID = info.dwID
				rec.szContent = ""
				rec.bTipWhenGroup = true
				rec.bAlertWhenGroup = false
			end
			if rec.dwID then
				ui:children("#WndButton_Submit"):enable(true)
				ui:children("#WndEditBox_ID"):text(rec.dwID)
				ui:children("#WndEditBox_Content"):text(rec.szContent)
				ui:children("#WndCheckBox_TipWhenGroup"):check(rec.bTipWhenGroup)
				ui:children("#WndCheckBox_AlertWhenGroup"):check(rec.bAlertWhenGroup)
			else
				ui:children("#WndButton_Submit"):enable(false)
				ui:children("#WndEditBox_ID"):text(_L['Not found in local store'])
			end
		end,
	})
	y = y + 30

	ui:append("Text", { x = x, y = y, text = _L['Content:'] })
	ui:append("WndEditBox", {
		name = "WndEditBox_Content",
		x = x + 60, y = y, w = 200, h = 80,
		multiline = true, text = note.szContent or "",
	})
	y = y + 90

	ui:append("WndCheckBox", {
		name = "WndCheckBox_AlertWhenGroup",
		x = x + 58, y = y, w = 200,
		text = _L['alert when group'],
		checked = note.bAlertWhenGroup,
	})
	y = y + 20

	ui:append("WndCheckBox", {
		name = "WndCheckBox_TipWhenGroup",
		x = x + 58, y = y, w = 200,
		text = _L['tip when group'],
		checked = note.bTipWhenGroup,
	})
	y = y + 30

	ui:append("WndButton", {
		name = "WndButton_Submit",
		x = x + 58, y = y, w = 80,
		text = _L['sure'],
		onclick = function()
			MY_Anmerkungen.SetPlayerNote(
				ui:children("#WndEditBox_ID"):text(),
				ui:children("#WndEditBox_Name"):text(),
				ui:children("#WndEditBox_Content"):text(),
				ui:children("#WndCheckBox_TipWhenGroup"):check(),
				ui:children("#WndCheckBox_AlertWhenGroup"):check()
			)
			ui:remove()
		end,
	})
	ui:append("WndButton", {
		x = x + 143, y = y, w = 80,
		text = _L['cancel'],
		onclick = function() ui:remove() end,
	})
	ui:append("Text", {
		x = x + 230, y = y + 3, w = 80, alpha = 200,
		text = _L['delete'], color = {255,0,0},
		onhover = function(bIn) MY.UI(this):alpha((bIn and 255) or 200) end,
		onclick = function()
			MY_Anmerkungen.SetPlayerNote(ui:children("#WndEditBox_ID"):text())
			ui:remove()
		end,
	})

	-- init
	Station.SetFocusWindow(ui[1])
	ui:children("#WndEditBox_Name"):change()
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end

do
local function onMenu()
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
end
MY.RegisterTargetAddonMenu("MY_Anmerkungen_PlayerNotes", onMenu)
end

do
local menu = {
	szOption = _L["View anmerkungen"],
	fnAction = function()
		MY.OpenPanel()
		MY.SwitchTab("MY_Anmerkungen")
	end,
}
MY.RegisterAddonMenu("MY_Anmerkungen_PlayerNotes", menu)
end

-- ��ȡһ����ҵļ�¼
-- MY_Anmerkungen.GetPlayerNote(dwID)
-- MY_Anmerkungen.GetPlayerNote(szName)
function MY_Anmerkungen.GetPlayerNote(dwID)
	local t
	local rec = PRIVATE_PLAYER_NOTES[PRIVATE_PLAYER_IDS[dwID] or dwID]
	if rec then
		t = clone(rec)
		t.bPrivate = true
	else
		rec = PUBLIC_PLAYER_NOTES[PUBLIC_PLAYER_IDS[dwID] or dwID]
		if rec then
			t = clone(rec)
			t.bPrivate = false
		end
	end
	return t
end

-- ����һ����ҵļ�¼
function MY_Anmerkungen.SetPlayerNote(dwID, szName, szContent, bTipWhenGroup, bAlertWhenGroup, bPrivate)
	dwID = dwID and tonumber(dwID)
	if not dwID then
		return nil
	end
	MY_Anmerkungen.LoadConfig()
	-- remove
	local rec = PRIVATE_PLAYER_NOTES[dwID]
	if rec then
		PRIVATE_PLAYER_IDS[rec.szName] = nil
		PRIVATE_PLAYER_NOTES[dwID] = nil
	end
	local rec = PUBLIC_PLAYER_NOTES[dwID]
	if rec then
		PUBLIC_PLAYER_IDS[rec.szName] = nil
		PUBLIC_PLAYER_NOTES[dwID] = nil
	end
	-- add
	if szName then
		local t = {
			dwID = dwID,
			szName = szName,
			szContent = szContent,
			bTipWhenGroup = bTipWhenGroup,
			bAlertWhenGroup = bAlertWhenGroup,
		}
		if bPrivate then
			PRIVATE_PLAYER_NOTES[dwID] = t
			PRIVATE_PLAYER_IDS[szName] = dwID
		else
			PUBLIC_PLAYER_NOTES[dwID] = t
			PUBLIC_PLAYER_IDS[szName] = dwID
		end
		if _C.list then
			_C.list:listbox('update', 'id', dwID, {"text", "data"}, { _L('[%s] %s', t.szName, t.szContent), t })
		end
	elseif _C.list then
		_C.list:listbox('delete', 'id', dwID)
	end
	MY_Anmerkungen.SaveConfig()
end

-- ������ҽ���ʱ
do
local function OnPartyAddMember()
	local dwID = arg1
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
MY.RegisterEvent("PARTY_ADD_MEMBER", OnPartyAddMember)
-- MY.RegisterEvent("PARTY_SYNC_MEMBER_DATA", OnPartyAddMember)
end

-- ��ȡ��������
function MY_Anmerkungen.LoadConfig()
	local data = MY.LoadLUAData({"config/anmerkungen.jx3dat", MY_DATA_PATH.SERVER})
	if data then
		PUBLIC_PLAYER_IDS = data.ids or {}
		PUBLIC_PLAYER_NOTES = data.data or {}
	end
	local szOrgFile = MY.GetLUADataPath("config/PLAYER_NOTES/$relserver.$lang.jx3dat")
	local szFilePath = MY.GetLUADataPath({"config/playernotes.jx3dat", MY_DATA_PATH.SERVER})
	if IsLocalFileExist(szOrgFile) then
		CPath.Move(szOrgFile, szFilePath)
	end
	if IsLocalFileExist(szFilePath) then
		local data = MY.LoadLUAData(szFilePath) or {}
		if type(data) == 'string' then
			data = MY.Json.Decode(data)
		end
		for k, v in pairs(data) do
			if type(v) == "table" then
				k = tonumber(k)
				v.dwID = tonumber(v.dwID)
				PUBLIC_PLAYER_NOTES[k] = v
			else
				PUBLIC_PLAYER_IDS[k] = tonumber(v)
			end
		end
		CPath.DelFile(szFilePath)
		MY_Anmerkungen.SaveConfig()
	end

	local data = MY.LoadLUAData({"config/anmerkungen.jx3dat", MY_DATA_PATH.ROLE})
	if data then
		PRIVATE_PLAYER_IDS = data.ids or {}
		PRIVATE_PLAYER_NOTES = data.data or {}
	end
	local szOrgFile = MY.GetLUADataPath("config/PLAYER_NOTES/$uid.$lang.jx3dat")
	local szFilePath = MY.GetLUADataPath({"config/playernotes.jx3dat", MY_DATA_PATH.ROLE})
	if IsLocalFileExist(szOrgFile) then
		CPath.Move(szOrgFile, szFilePath)
	end
	if IsLocalFileExist(szFilePath) then
		local data = MY.LoadLUAData(szFilePath) or {}
		if type(data) == 'string' then
			data = MY.Json.Decode(data)
		end
		for k, v in pairs(data) do
			if type(v) == "table" then
				k = tonumber(k)
				v.dwID = tonumber(v.dwID)
				PRIVATE_PLAYER_NOTES[k] = v
			else
				PRIVATE_PLAYER_IDS[k] = tonumber(v)
			end
		end
		CPath.DelFile(szFilePath)
		MY_Anmerkungen.SaveConfig()
	end
end
-- ���湫������
function MY_Anmerkungen.SaveConfig()
	local data = {
		ids = PUBLIC_PLAYER_IDS,
		data = PUBLIC_PLAYER_NOTES,
	}
	MY.SaveLUAData({"config/anmerkungen.jx3dat", MY_DATA_PATH.SERVER}, data)

	local data = {
		ids = PRIVATE_PLAYER_IDS,
		data = PRIVATE_PLAYER_NOTES,
	}
	MY.SaveLUAData({"config/anmerkungen.jx3dat", MY_DATA_PATH.ROLE}, data)
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
							if type(v) == "table" then
								k = tonumber(k)
								if not PUBLIC_PLAYER_NOTES[k] or usenew then
									v.dwID = tonumber(v.dwID)
									PUBLIC_PLAYER_NOTES[k] = v
								end
							else
								v = tonumber(v)
								PUBLIC_PLAYER_IDS[k] = v
							end
						end
						for k, v in pairs(config.publici) do
							if not PUBLIC_PLAYER_IDS[k] or usenew then
								PUBLIC_PLAYER_IDS[k] = v
							end
						end
						for k, v in pairs(config.publicd) do
							if not PUBLIC_PLAYER_NOTES[k] or usenew then
								PUBLIC_PLAYER_NOTES[k] = v
							end
						end
						for k, v in pairs(config.private) do
							if type(v) == "table" then
								k = tonumber(k)
								if not PRIVATE_PLAYER_NOTES[k] or usenew then
									v.dwID = tonumber(v.dwID)
									PRIVATE_PLAYER_NOTES[k] = v
								end
							else
								v = tonumber(v)
								PRIVATE_PLAYER_IDS[k] = v
							end
						end
						for k, v in pairs(config.privatei) do
							if not PRIVATE_PLAYER_IDS[k] or usenew then
								PRIVATE_PLAYER_IDS[k] = v
							end
						end
						for k, v in pairs(config.privated) do
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
				server   = MY.GetRealServer(),
				publici  = PUBLIC_PLAYER_IDS,
				publicd  = PUBLIC_PLAYER_NOTES,
				privatei = PRIVATE_PLAYER_IDS,
				privated = PRIVATE_PLAYER_NOTES,
			}))
		end,
	})

	y = y + 30
	local list = ui:append("WndListBox", {
		x = x, y = y,
		w = w, h = h - 30,
		listbox = {{
			'onlclick',
			function(hItem, szText, szID, data, bSelected)
				MY_Anmerkungen.OpenPlayerNoteEditPanel(data.dwID, data.szName)
				return false
			end,
		}},
	}, true)
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
