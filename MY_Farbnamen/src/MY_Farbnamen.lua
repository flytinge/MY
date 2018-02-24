--
-- ���촰������Ⱦɫ���
-- By ����@˫����@ݶ����
-- 2014��5��19��05:07:02
--
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."MY_Farbnamen/lang/")
local _SUB_ADDON_FOLDER_NAME_ = "MY_Farbnamen"
local XML_LINE_BREAKER = XML_LINE_BREAKER
local tinsert, tconcat, tremove = table.insert, table.concat, table.remove
---------------------------------------------------------------
-- ���ú�����
---------------------------------------------------------------
MY.CreateDataRoot(MY_DATA_PATH.SERVER)
local SZ_DB_PATH = MY.FormatPath({"cache/player_info.db", MY_DATA_PATH.SERVER})
local DB = SQLite3_Open(SZ_DB_PATH)
if not DB then
	return MY.Sysmsg({_L['Cannot connect to database!!!'], r = 255, g = 0, b = 0}, _L["MY_Farbnamen"])
end
DB:Execute("CREATE TABLE IF NOT EXISTS InfoCache (id INTEGER PRIMARY KEY, name VARCHAR(20) NOT NULL, force INTEGER, role INTEGER, level INTEGER, title VARCHAR(20), camp INTEGER, tong INTEGER)")
DB:Execute("CREATE INDEX IF NOT EXISTS info_cache_name_idx ON InfoCache(name)")
local DBI_W  = DB:Prepare("REPLACE INTO InfoCache (id, name, force, role, level, title, camp, tong) VALUES (?, ?, ?, ?, ?, ?, ?, ?)")
local DBI_RI = DB:Prepare("SELECT id, name, force, role, level, title, camp, tong FROM InfoCache WHERE id = ?")
local DBI_RN = DB:Prepare("SELECT id, name, force, role, level, title, camp, tong FROM InfoCache WHERE name = ?")
DB:Execute("CREATE TABLE IF NOT EXISTS TongCache (id INTEGER PRIMARY KEY, name VARCHAR(20))")
local DBT_W  = DB:Prepare("REPLACE INTO TongCache (id, name) VALUES (?, ?)")
local DBT_RI = DB:Prepare("SELECT id, name FROM InfoCache WHERE id = ?")

MY_Farbnamen = MY_Farbnamen or {
	bEnabled = true,
}
RegisterCustomData("MY_Farbnamen.bEnabled")

do if IsDebugClient() then -- �ɰ滺��ת��
	local SZ_IC_PATH = MY.FormatPath("cache/PLAYER_INFO/$relserver/")
	if IsLocalFileExist(SZ_IC_PATH) then
		MY.Debug({"Farbnamen info cache trans from file to sqlite start!"}, "MY_Farbnamen", MY_DEBUG.LOG)
		DB:Execute("BEGIN TRANSACTION")
		for i = 0, 999 do
			local data = MY.LoadLUAData("cache/PLAYER_INFO/$relserver/DAT2/" .. i .. ".$lang.jx3dat")
			if data then
				for id, p in pairs(data) do
					DBI_W:ClearBindings()
					DBI_W:BindAll(p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8])
					DBI_W:Execute()
				end
			end
		end
		DB:Execute("END TRANSACTION")
		MY.Debug({"Farbnamen info cache trans from file to sqlite finished!"}, "MY_Farbnamen", MY_DEBUG.LOG)

		MY.Debug({"Farbnamen tong cache trans from file to sqlite start!"}, "MY_Farbnamen", MY_DEBUG.LOG)
		DB:Execute("BEGIN TRANSACTION")
		for i = 0, 128 do
			for j = 0, 128 do
				local data = MY.LoadLUAData("cache/PLAYER_INFO/$relserver/TONG/" .. i .. "-" .. j .. ".$lang.jx3dat")
				if data then
					for id, name in pairs(data) do
						DBT_W:ClearBindings()
						DBT_W:BindAll(id, name)
						DBT_W:Execute()
					end
				end
			end
		end
		DB:Execute("END TRANSACTION")
		MY.Debug({"Farbnamen tong cache trans from file to sqlite finished!"}, "MY_Farbnamen", MY_DEBUG.LOG)

		MY.Debug({"Farbnamen cleaning file cache start: " .. SZ_IC_PATH}, "MY_Farbnamen", MY_DEBUG.LOG)
		CPath.DelDir(SZ_IC_PATH)
		MY.Debug({"Farbnamen cleaning file cache finished!"}, "MY_Farbnamen", MY_DEBUG.LOG)
	end
end end

local _MY_Farbnamen = {
	tForceString = clone(g_tStrings.tForceTitle),
	tRoleType    = {
		[ROLE_TYPE.STANDARD_MALE  ] = _L['man'],
		[ROLE_TYPE.STANDARD_FEMALE] = _L['woman'],
		[ROLE_TYPE.LITTLE_BOY     ] = _L['boy'],
		[ROLE_TYPE.LITTLE_GIRL    ] = _L['girl'],
	},
	tCampString  = clone(g_tStrings.STR_GUILD_CAMP_NAME),
	aPlayerQueu = {},
}
---------------------------------------------------------------
-- ���츴�ƺ�ʱ����ʾ���
---------------------------------------------------------------
-- �����������ݵ� HOOK �����ˡ�����ʱ�� ��
MY.HookChatPanel("MY_FARBNAMEN", function(h, szChannel, szMsg, dwTime)
	return szMsg, h:GetItemCount()
end, function(h, nCount, szChannel, szMsg, dwTime)
	if MY_Farbnamen.bEnabled then
		for i = h:GetItemCount() - 1, nCount or 0, -1 do
			MY_Farbnamen.Render(h:Lookup(i))
		end
	end
end, function(h)
	for i = h:GetItemCount() - 1, 0, -1 do
		MY_Farbnamen.Render(h:Lookup(i))
	end
end)
-- ���ŵ�����Ⱦɫ�ӿ�
-- (userdata) MY_Farbnamen.Render(userdata namelink)    ����namelinkȾɫ namelink��һ������TextԪ��
-- (string) MY_Farbnamen.Render(string szMsg)           ��ʽ��szMsg �������������
function MY_Farbnamen.Render(szMsg)
	if type(szMsg) == 'string' then
		-- <text>text="[���Ǹ�����]" font=10 r=255 g=255 b=255  name="namelink_4662931" eventid=515</text><text>text="˵��" font=10 r=255 g=255 b=255 </text><text>text="[����]" font=10 r=255 g=255 b=255  name="namelink_4662931" eventid=771</text><text>text="\n" font=10 r=255 g=255 b=255 </text>
		local xml = MY.Xml.Decode(szMsg)
		if xml then
			for _, ele in ipairs(xml) do
				if ele[''].name and ele[''].name:sub(1, 9) == 'namelink_' then
					local szName = string.gsub(ele[''].text, '[%[%]]', '')
					local tInfo = MY_Farbnamen.GetAusName(szName)
					if tInfo then
						ele[''].r = tInfo.rgb[1]
						ele[''].g = tInfo.rgb[2]
						ele[''].b = tInfo.rgb[3]
					end
					ele[''].eventid = 82803
					ele[''].script = (ele[''].script or '') .. '\nthis.OnItemMouseEnter=function() MY_Farbnamen.ShowTip(this) end\nthis.OnItemMouseLeave=function() HideTip() end'
				end
			end
			szMsg = MY.Xml.Encode(xml)
		end
		-- szMsg = string.gsub( szMsg, '<text>([^<]-)text="([^<]-)"([^<]-name="namelink_%d-"[^<]-)</text>', function (szExtra1, szName, szExtra2)
		--     szName = string.gsub(szName, '[%[%]]', '')
		--     local tInfo = MY_Farbnamen.GetAusName(szName)
		--     if tInfo then
		--         szExtra1 = string.gsub(szExtra1, '[rgb]=%d+', '')
		--         szExtra2 = string.gsub(szExtra2, '[rgb]=%d+', '')
		--         szExtra1 = string.gsub(szExtra1, 'eventid=%d+', '')
		--         szExtra2 = string.gsub(szExtra2, 'eventid=%d+', '')
		--         return string.format(
		--             '<text>%stext="[%s]"%s eventid=883 script="this.OnItemMouseEnter=function() MY_Farbnamen.ShowTip(this) end\nthis.OnItemMouseLeave=function() HideTip() end" r=%d g=%d b=%d</text>',
		--             szExtra1, szName, szExtra2, tInfo.rgb[1], tInfo.rgb[2], tInfo.rgb[3]
		--         )
		--     end
		-- end)
	elseif type(szMsg) == 'table' and type(szMsg.GetName) == 'function' and szMsg:GetName():sub(1, 8) == 'namelink' then
		local namelink = szMsg
		local ui = MY.UI(namelink):hover(MY_Farbnamen.ShowTip, HideTip, true)
		local szName = string.gsub(namelink:GetText(), '[%[%]]', '')
		local tInfo = MY_Farbnamen.GetAusName(szName)
		if tInfo then
			ui:color(tInfo.rgb)
		end
	end
	return szMsg
end

function MY_Farbnamen.GetTip(szName)
	local tInfo = MY_Farbnamen.GetAusName(szName)
	if tInfo then
		local tTip = {}
		-- author info
		if tInfo.dwID and tInfo.szName and tInfo.szName == MY.GetAddonInfo().tAuthor[tInfo.dwID] then
			tinsert(tTip, GetFormatText(_L['mingyi plugins'], 8, 89, 224, 232))
			tinsert(tTip, GetFormatText(' ', 136, 89, 224, 232))
			tinsert(tTip, GetFormatText(_L['[author]'], 8, 89, 224, 232))
			tinsert(tTip, XML_LINE_BREAKER)
		end
		-- ���� �ȼ�
		tinsert(tTip, GetFormatText(('%s(%d)'):format(tInfo.szName, tInfo.nLevel), 136))
		-- �Ƿ�ͬ����
		if UI_GetClientPlayerID() ~= tInfo.dwID and MY.IsParty(tInfo.dwID) then
			tinsert(tTip, GetFormatText(_L['[teammate]'], nil, 0, 255, 0))
		end
		tinsert(tTip, XML_LINE_BREAKER)
		-- �ƺ�
		if tInfo.szTitle and #tInfo.szTitle > 0 then
			tinsert(tTip, GetFormatText('<' .. tInfo.szTitle .. '>', 136))
			tinsert(tTip, XML_LINE_BREAKER)
		end
		-- ���
		if tInfo.szTongID and #tInfo.szTongID > 0 then
			tinsert(tTip, GetFormatText('[' .. tInfo.szTongID .. ']', 136))
			tinsert(tTip, XML_LINE_BREAKER)
		end
		-- ���� ���� ��Ӫ
		tinsert(tTip, GetFormatText(
			(_MY_Farbnamen.tForceString[tInfo.dwForceID] or tInfo.dwForceID) .. _L.STR_SPLIT_DOT ..
			(_MY_Farbnamen.tRoleType[tInfo.nRoleType] or tInfo.nRoleType)    .. _L.STR_SPLIT_DOT ..
			(_MY_Farbnamen.tCampString[tInfo.nCamp] or tInfo.nCamp), 136
		))
		tinsert(tTip, XML_LINE_BREAKER)
		-- ������
		if MY_Anmerkungen and MY_Anmerkungen.GetPlayerNote then
			local note = MY_Anmerkungen.GetPlayerNote(tInfo.dwID)
			if note and note.szContent ~= "" then
				tinsert(tTip, GetFormatText(note.szContent, 0))
				tinsert(tTip, XML_LINE_BREAKER)
			end
		end
		-- ������Ϣ
		if IsCtrlKeyDown() then
			tinsert(tTip, XML_LINE_BREAKER)
			tinsert(tTip, GetFormatText(_L("Player ID: %d", tInfo.dwID), 102))
		end
		-- ��װTip
		return tconcat(tTip)
	end
end

function MY_Farbnamen.ShowTip(namelink)
	if type(namelink) ~= "table" then
		namelink = this
	end
	if not namelink then
		return
	end
	local szName = string.gsub(namelink:GetText(), '[%[%]]', '')
	local x, y = namelink:GetAbsPos()
	local w, h = namelink:GetSize()

	local szTip = MY_Farbnamen.GetTip(szName)
	if szTip then
		OutputTip(szTip, 450, {x, y, w, h}, MY.Const.UI.Tip.POS_TOP)
	end
end
---------------------------------------------------------------
-- ���ݴ洢
---------------------------------------------------------------
local l_infocache       = {} -- ��ȡ���ݻ���
local l_infocache_w     = {} -- �޸����ݻ���
local l_remoteinfocache = {} -- ������ݻ���
local l_tongnames       = {} -- ������ݻ���
local l_tongnames_w     = {} -- ����޸����ݻ���
local function GetTongName(dwID)
	if not dwID then
		return
	end
	local szTong = l_tongnames[dwID]
	if not szTong then
		DBT_RI:ClearBindings()
		DBT_RI:BindAll(dwID)
		local data = DBT_RI:GetNext()
		if data then
			szTong = data.name
			l_tongnames[dwID] = data.name
		end
	end
	return szTong
end

local function OnExit()
	DB:Execute("BEGIN TRANSACTION")
	for i, p in pairs(l_infocache_w) do
		DBI_W:ClearBindings()
		DBI_W:BindAll(p.id, p.name, p.force, p.role, p.level, p.title, p.camp, p.tong)
		DBI_W:Execute()
	end
	DB:Execute("END TRANSACTION")

	DB:Execute("BEGIN TRANSACTION")
	for id, name in pairs(l_tongnames_w) do
		DBT_W:ClearBindings()
		DBT_W:BindAll(id, name)
		DBT_W:Execute()
	end
	DB:Execute("END TRANSACTION")

	DB:Release()
end
MY.RegisterExit("MY_Farbnamen_Save", OnExit)

-- ͨ��szName��ȡ��Ϣ
function MY_Farbnamen.Get(szKey)
	local info = l_remoteinfocache[szKey] or l_infocache[szKey]
	if not info then
		if type(szKey) == "string" then
			DBI_RN:ClearBindings()
			DBI_RN:BindAll(szKey)
			info = DBI_RN:GetNext()
		elseif type(szKey) == "number" then
			DBI_RI:ClearBindings()
			DBI_RI:BindAll(szKey)
			info = DBI_RI:GetNext()
		end
		if info then
			l_infocache[info.id] = info
			l_infocache[info.name] = info
		end
	end
	if info then
		return {
			dwID      = info.id,
			szName    = info.name,
			dwForceID = info.force,
			nRoleType = info.role,
			nLevel    = info.level,
			szTitle   = info.title,
			nCamp     = info.camp,
			szTongID  = GetTongName(info.tong) or "",
			rgb       = { MY.GetForceColor(info.force, "forecolor") },
		}
	end
end
MY_Farbnamen.GetAusName = MY_Farbnamen.Get

-- ͨ��dwID��ȡ��Ϣ
function MY_Farbnamen.GetAusID(dwID)
	MY_Farbnamen.AddAusID(dwID)
	return MY_Farbnamen.Get(dwID)
end

-- ����ָ��dwID�����
function MY_Farbnamen.AddAusID(dwID)
	local player = GetPlayer(dwID)
	if not player or not player.szName or player.szName == "" then
		return false
	else
		local info = l_infocache[player.dwID] or {}
		info.id    = player.dwID
		info.name  = player.szName
		info.force = player.dwForceID or -1
		info.role  = player.nRoleType or -1
		info.level = player.nLevel or -1
		info.title = player.nX ~= 0 and player.szTitle or info.title
		info.camp  = player.nCamp or -1
		info.tong  = player.dwTongID or -1

		if IsRemotePlayer(info.id) then
			l_infocache[info.id] = info
			l_infocache[info.name] = info
		else
			local dwTongID = player.dwTongID
			if dwTongID and dwTongID ~= 0 then
				local szTong = GetTongClient().ApplyGetTongName(dwTongID, 254)
				if szTong and szTong ~= "" then
					l_tongnames[dwTongID] = szTong
					l_tongnames_w[dwTongID] = szTong
				end
			end
			l_infocache[info.id] = info
			l_infocache[info.name] = info
			l_infocache_w[info.id] = info
		end
		return true
	end
end

--------------------------------------------------------------
-- �˵�
--------------------------------------------------------------
function MY_Farbnamen.GetMenu()
	local t = {szOption = _L['Farbnamen']}
	table.insert(t, {
		szOption = _L["enable"],
		fnAction = function()
			MY_Farbnamen.bEnabled = not MY_Farbnamen.bEnabled
		end,
		bCheck = true,
		bChecked = MY_Farbnamen.bEnabled
	})
	table.insert(t, {
		szOption = _L['customize color'],
		fnAction = function()
			MY.OpenPanel()
			MY.SwitchTab("GlobalColor")
		end,
		fnDisable = function()
			return not MY_Farbnamen.bEnabled
		end,
	})
	table.insert(t, {
		szOption = _L["reset data"],
		fnAction = function()
			DB:Execute("DELETE FROM InfoCache")
			MY.Sysmsg({_L['cache data deleted.']}, _L['Farbnamen'])
		end,
		fnDisable = function()
			return not MY_Farbnamen.bEnabled
		end,
	})
	return t
end
MY.RegisterAddonMenu('MY_Farbenamen', MY_Farbnamen.GetMenu)
--------------------------------------------------------------
-- ע���¼�
--------------------------------------------------------------
do
local l_peeklist = {}
local function onBreathe()
	for dwID, nRetryCount in pairs(l_peeklist) do
		if MY_Farbnamen.AddAusID(dwID) or nRetryCount > 5 then
			l_peeklist[dwID] = nil
		else
			l_peeklist[dwID] = nRetryCount + 1
		end
	end
end
MY.BreatheCall(250, onBreathe)

local function OnPeekPlayer()
	if arg0 == PEEK_OTHER_PLAYER_RESPOND.SUCCESS then
		l_peeklist[arg1] = 0
	end
end
MY.RegisterEvent("PEEK_OTHER_PLAYER", OnPeekPlayer)
MY.RegisterEvent("PLAYER_ENTER_SCENE", function() l_peeklist[arg0] = 0 end)
MY.RegisterEvent("ON_GET_TONG_NAME_NOTIFY", function() l_tongnames[arg1], l_tongnames_w[arg1] = arg2, arg2 end)
end
