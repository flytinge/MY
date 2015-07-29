--
-- �����¼
-- ��¼�Ŷ�/����/���/���� ���պ��ѯ
-- ���ߣ���һ�� @ tinymins
-- ��վ��ZhaiYiMing.CoM
--
local _L  = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."Chat/lang/")
local _C  = {}
local Log = {}
local XML_LINE_BREAKER = XML_LINE_BREAKER
local tinsert, tconcat, tremove = table.insert, table.concat, table.remove
MY_ChatLog = MY_ChatLog or {}
MY_ChatLog.szActiveChannel         = "MSG_WHISPER" -- ��ǰ����ı�ǩҳ
MY_ChatLog.bIgnoreTongOnlineMsg    = true -- �������֪ͨ
MY_ChatLog.bIgnoreTongMemberLogMsg = true -- ����Ա����������ʾ
RegisterCustomData('MY_ChatLog.bIgnoreTongOnlineMsg')
RegisterCustomData('MY_ChatLog.bIgnoreTongMemberLogMsg')

------------------------------------------------------------------------------------------------------
--        #       #             #                               # # # #           #     #           --
--    #   #   #   #             #     # # # # # #     # # # # #                 # # # # # # # # #   --
--        #       #             #     #         #           #                 # #       #           --
--  # # # # # #   # # # #   # # # #   # # # # # #     #       #       #     #   # # # # # # # #     --
--      # #     #     #         #     #     #           #           #           #       #           --
--    #   # #     #   #         #     # # # # # #             #                 # # # # # # # #     --
--  #     #   #   #   #         # #   #     #       # # # # # # # # # # #       #       #           --
--      #         #   #     # # #     # # # # # #           # # #               # # # # # # # # #   --
--  # # # # #     #   #         #     # #       #         #   #   #                   #             --
--    #     #       #           #   #   #       #       #     #     #       # # # # # # # # # # #   --
--      # #       #   #         #   #   # # # # #   # #       #       # #       #     #     #       --
--  # #     #   #       #     # # #     #       #             #             # #       #       # #   --
------------------------------------------------------------------------------------------------------
-- ���ݲɼ� --
_C.TongOnlineMsg       = '^' .. MY.String.PatternEscape(g_tStrings.STR_TALK_HEAD_TONG .. g_tStrings.STR_GUILD_ONLINE_MSG)
_C.TongMemberLoginMsg  = '^' .. MY.String.PatternEscape(g_tStrings.STR_GUILD_MEMBER_LOGIN):gsub('<link 0>', '.-') .. '$'
_C.TongMemberLogoutMsg = '^' .. MY.String.PatternEscape(g_tStrings.STR_GUILD_MEMBER_LOGOUT):gsub('<link 0>', '.-') .. '$'

function _C.OnMsg(szMsg, szChannel, nFont, bRich, r, g, b)
	local szText = szMsg
	if bRich then
		szText = GetPureText(szMsg)
	else
		szMsg = GetFormatText(szMsg, nil, r, g, b)
	end
	-- filters
	if szChannel == "MSG_GUILD" then
		if MY_ChatLog.bIgnoreTongOnlineMsg and szText:find(_C.TongOnlineMsg) then
			return
		end
		if MY_ChatLog.bIgnoreTongMemberLogMsg and (
			szText:find(_C.TongMemberLoginMsg) or szText:find(_C.TongMemberLogoutMsg)
		) then
			return
		end
	end
	-- generate rec
	szMsg = MY.Chat.GetTimeLinkText({r=r, g=g, b=b, f=nFont, s='[hh:mm:ss]'}) .. szMsg
	-- save and draw rec
	_C.AppendLog(szChannel, _C.GetCurrentDate(), szMsg)
	_C.UiAppendLog(szChannel, szMsg)
end

function _C.OnTongMsg(szMsg, nFont, bRich, r, g, b)
	_C.OnMsg(szMsg, 'MSG_GUILD', nFont, bRich, r, g, b)
end
function _C.OnWisperMsg(szMsg, nFont, bRich, r, g, b)
	_C.OnMsg(szMsg, 'MSG_WHISPER', nFont, bRich, r, g, b)
end
function _C.OnRaidMsg(szMsg, nFont, bRich, r, g, b)
	_C.OnMsg(szMsg, 'MSG_TEAM', nFont, bRich, r, g, b)
end
function _C.OnFriendMsg(szMsg, nFont, bRich, r, g, b)
	_C.OnMsg(szMsg, 'MSG_FRIEND', nFont, bRich, r, g, b)
end

MY.RegisterInit("MY_CHATLOG_REGMSG", function()
	MY.RegisterMsgMonitor('MY_ChatLog_Tong'  , _C.OnTongMsg  , { 'MSG_GUILD', 'MSG_GUILD_ALLIANCE' })
	MY.RegisterMsgMonitor('MY_ChatLog_Wisper', _C.OnWisperMsg, { 'MSG_WHISPER' })
	MY.RegisterMsgMonitor('MY_ChatLog_Raid'  , _C.OnRaidMsg  , { 'MSG_TEAM', 'MSG_PARTY', 'MSG_GROUP' })
	MY.RegisterMsgMonitor('MY_ChatLog_Friend', _C.OnFriendMsg, { 'MSG_FRIEND' })
end)
------------------------------------------------------------------------------------------------------
--        #       #             #                           #                                       --
--    #   #   #   #             #     # # # # # #           #               # # # # # #             --
--        #       #             #     #         #   # # # # # # # # # # #     #     #   # # # #     --
--  # # # # # #   # # # #   # # # #   # # # # # #         #                   #     #     #   #     --
--      # #     #     #         #     #     #           #     # # # # #       # # # #     #   #     --
--    #   # #     #   #         #     # # # # # #       #           #         #     #     #   #     --
--  #     #   #   #   #         # #   #     #         # #         #           # # # #     #   #     --
--      #         #   #     # # #     # # # # # #   #   #   # # # # # # #     #     #     #   #     --
--  # # # # #     #   #         #     # #       #       #         #           #     # #     #       --
--    #     #       #           #   #   #       #       #         #         # # # # #       #       --
--      # #       #   #         #   #   # # # # #       #         #                 #     #   #     --
--  # #     #   #       #     # # #     #       #       #       # #                 #   #       #   --
------------------------------------------------------------------------------------------------------
-- ���ݴ�ȡ --
--[[
	Log = {
		MSG_WHISPER = {
			DateList = { 20150214, 20150215 }
			DateIndex = { [20150214] = 1, [20150215] = 2 }
			[20150214] = { <szMsg>, <szMsg>, ... },
			[20150215] = { <szMsg>, <szMsg>, ... },
			...
		},
		...
	}
]]
local DATA_PATH = 'userdata/CHAT_LOG/$uid/%s/%s.$lang.jx3dat'

_C.tModifiedLog = {}
function _C.GetCurrentDate()
	return tonumber(MY.Sys.FormatTime("yyyyMMdd", GetCurrentTime()))
end

function _C.RebuildDateList(tChannels, nScanDays)
	_C.UnloadLog()
	for _, szChannel in ipairs(tChannels) do
		Log[szChannel] = { DateList = {} }
		local nEndedDate = tonumber(MY.Sys.FormatTime("yyyyMMdd", GetCurrentTime()))
		local nStartDate = nEndedDate - nScanDays
		local tDateList  = Log[szChannel].DateList
		for dwDate = nStartDate, nEndedDate do
			if IsFileExist(MY.GetLUADataPath(DATA_PATH:format(szChannel, dwDate))) then
				tinsert(tDateList, dwDate)
				_C.tModifiedLog[szChannel] = { DateList = true }
			end
		end
	end
	_C.UnloadLog()
end

function _C.GetDateList(szChannel)
	if not Log[szChannel] then
		Log[szChannel] = {}
		Log[szChannel].DateList = MY.LoadLUAData(DATA_PATH:format(szChannel, 'DateList')) or {}
		Log[szChannel].DateIndex = {}
		for i, dwDate in ipairs(Log[szChannel].DateList) do
			Log[szChannel].DateIndex[dwDate] = i
		end
	end
	return Log[szChannel].DateList, Log[szChannel].DateIndex
end

function _C.GetLog(szChannel, dwDate)
	_C.GetDateList(szChannel)
	if not Log[szChannel][dwDate] then
		Log[szChannel][dwDate] = MY.LoadLUAData(DATA_PATH:format(szChannel, dwDate)) or {}
	end
	return Log[szChannel][dwDate]
end

function _C.AppendLog(szChannel, dwDate, szMsg)
	local log = _C.GetLog(szChannel, dwDate)
	tinsert(log, szMsg)
	-- mark as modified
	if not _C.tModifiedLog[szChannel] then
		_C.tModifiedLog[szChannel] = {}
	end
	_C.tModifiedLog[szChannel][dwDate] = true
	-- append datelist
	local DateList, DateIndex = _C.GetDateList(szChannel)
	if not DateIndex[dwDate] then
		tinsert(DateList, dwDate)
		DateIndex[dwDate] = #DateList
		_C.tModifiedLog[szChannel]['DateList'] = true
	end
end

function _C.UnloadLog()
	for szChannel, tDate in pairs(_C.tModifiedLog) do
		for dwDate, _ in pairs(tDate) do
			if not empty(Log[szChannel][dwDate]) then
				MY.SaveLUAData(DATA_PATH:format(szChannel, dwDate), Log[szChannel][dwDate])
			end
		end
	end
	Log = {}
	_C.tModifiedLog = {}
end
MY.RegisterExit(_C.UnloadLog)

------------------------------------------------------------------------------------------------------
--    # # # # # # # # #                                 #         #               #             #   --
--    #       #       #     # # # # # # # # # # #       #       #   #         #   #             #   --
--    # # # # # # # # #               #               #       #       #       # # # # #   #     #   --
--    #       #       #             #               #     # #           #   #     #       #     #   --
--    # # # # # # # # #       # # # # # # # # # #   # # #     # # # # #     # # # # # # # #     #   --
--            #               #     #     #     #       #                         #       #     #   --
--        # #   # #           #     # # # #     #     #                       # # # # #   #     #   --
--  # # #           # # #     #     #     #     #   # # #   # # # # # # #     #   #   #   #     #   --
--        #       #           #     # # # #     #               #             #   #   #   #     #   --
--        #       #           #     #     #     #       #     #       #       #   #   #         #   --
--      #         #           # # # # # # # # # #   # #     # # # # # # #     #   # # #         #   --
--    #           #           #                 #                       #         #         # # #   --
------------------------------------------------------------------------------------------------------
-- ������� --
function _C.UiRedrawLog()
	if not _C.uiLog then
		return
	end
	_C.uiLog:clear()
	_C.nDrawDate  = nil
	_C.nDrawIndex = nil
	_C.UiDrawPrev(20)
	_C.uiLog:scroll(100)
	if MY_ChatMosaics and MY_ChatMosaics.Mosaics then
		MY_ChatMosaics.Mosaics(_C.uiLog:hdl(1):raw(1))
	end
end

-- ���ظ���
function _C.UiDrawPrev(nCount)
	if not _C.uiLog or _C.bUiDrawing == GetLogicFrameCount() then
		return
	end
	local h = _C.uiLog:hdl(1):raw(1)
	local szChannel = MY_ChatLog.szActiveChannel
	local DateList, DateIndex = _C.GetDateList(szChannel)
	if #DateList == 0 or -- û�м�¼���Լ���
	(_C.nDrawDate == DateList[1] and _C.nDrawIndex == 0) then -- û�и���ļ�¼���Լ���
		return
	elseif not _C.nDrawDate then -- ��û�м��ؽ���
		_C.nDrawDate = DateList[#DateList]
	end
	local nPos = 0
	local nLen = h:GetItemCount()
	-- ��ֹUI�ݹ���ѭ�� ��Դ��
	_C.bUiDrawing = GetLogicFrameCount()
	-- ���浱ǰ������λ��
	local _, nH = h:GetSize()
	local _, nOrginScrollH = h:GetAllItemSize()
	local nOrginScrollY = (nOrginScrollH - nH) * _C.uiLog:scroll() / 100
	-- ���������¼
	while nCount > 0 do
		-- ����ָ�����ڵļ�¼
		local log = _C.GetLog(szChannel, _C.nDrawDate)
		-- nDrawIndexΪ��������һ����ʼ����
		if not _C.nDrawIndex then
			_C.nDrawIndex = #log
		end
		-- ��������ڵļ�¼�Ƿ��㹻����ʣ�����������
		if _C.nDrawIndex > nCount then -- �㹻 ��ֱ�Ӽ���
			h:InsertItemFromString(0, false, tconcat(log, "", _C.nDrawIndex - nCount + 1, _C.nDrawIndex))
			_C.nDrawIndex = _C.nDrawIndex - nCount
			nCount = 0
		else -- ���� �������󽫼��ؽ���ָ����һ������
			h:InsertItemFromString(0, false, tconcat(log, "", 1, _C.nDrawIndex))
			h:InsertItemFromString(0, false, GetFormatText("========== " .. _C.nDrawDate .. " ==========\n")) -- ������������ڴ�
			-- �жϻ���û�м�¼���Լ���
			local nIndex = DateIndex[_C.nDrawDate]
			if nIndex == 1 then -- û�м�¼���Լ�����
				nCount = 0
				_C.nDrawIndex = 0
			else -- ���м�¼
				nCount = nCount - _C.nDrawIndex
				_C.nDrawDate = DateList[nIndex - 1]
				_C.nDrawIndex = nil
			end
		end
	end
	h:FormatAllItemPos()
	nLen = h:GetItemCount() - nLen
	MY_ChatMosaics.Mosaics(h, nPos, nLen)
	for i = 0, nLen do
		local hItem = h:Lookup(i)
		MY.Chat.RenderLink(hItem)
		if MY_Farbnamen and MY_Farbnamen.Render then
			MY_Farbnamen.Render(hItem)
		end
	end
	-- �ָ�֮ǰ������λ��
	if nOrginScrollY < 0 then -- ֮ǰû�й�����
		if _C.uiLog:scroll() >= 0 then -- �����й�����
			_C.uiLog:scroll(100)
		end
	else
		local _, nScrollH = h:GetAllItemSize()
		local nDeltaScrollH = nScrollH - nOrginScrollH
		_C.uiLog:scroll((nDeltaScrollH + nOrginScrollY) / (nScrollH - nH) * 100)
	end
	-- ��ֹUI�ݹ���ѭ�� ��Դ�����
	_C.bUiDrawing = nil
end

function _C.UiAppendLog(szChannel, szMsg)
	if not (_C.uiLog and szChannel == MY_ChatLog.szActiveChannel) then
		return
	end
	local bBottom = _C.uiLog:scroll() == 100
	if MY_ChatMosaics then
		local h = _C.uiLog:hdl(1):raw(1)
		local nCount
		if h then
			nCount = h:GetItemCount()
		end
		_C.uiLog:append(szMsg)
		if nCount then
			MY_ChatMosaics.Mosaics(h, nCount)
			for i = nCount, h:GetItemCount() - 1 do
				local hItem = h:Lookup(i)
				MY.Chat.RenderLink(hItem)
				if MY_Farbnamen and MY_Farbnamen.Render then
					MY_Farbnamen.Render(hItem)
				end
			end
		end
	else
		_C.uiLog:append(szMsg)
	end
	if bBottom then
		_C.uiLog:scroll(100)
	end
end

function _C.OnPanelActive(wnd)
	local ui = MY.UI(wnd)
	local w, h = ui:size()
	local x, y = 20, 10
	
	_C.uiLog = ui:append("WndScrollBox", "WndScrollBox_Log", {
		x = 20, y = 35, w = w - 21, h = h - 40, handlestyle = 3,
		onscroll = function(nScrollPercent, nScrollDistance)
			if nScrollPercent == 0 -- ��ǰ������λ��Ϊ0
			or (nScrollPercent == -1 and nScrollDistance == -1) then -- ��û�й���������������Ϲ���
				_C.UiDrawPrev(20)
			end
		end,
	}):children('#WndScrollBox_Log')
	
	for i, szChannel in ipairs({
		'MSG_GUILD'  ,
		'MSG_WHISPER',
		'MSG_TEAM'   ,
		'MSG_FRIEND' ,
	}) do
		ui:append('WndRadioBox', 'RadioBox_' .. szChannel):children('#RadioBox_' .. szChannel)
		  :pos(x + (i - 1) * 100, y):width(90)
		  :text(g_tStrings.tChannelName[szChannel] or '')
		  :check(function(bChecked)
		  	if bChecked then
		  		MY_ChatLog.szActiveChannel = szChannel
		  	end
		  	_C.UiRedrawLog()
		  end)
		  :check(MY_ChatLog.szActiveChannel == szChannel)
	end
	
	ui:append("Image", "Image_Setting"):item('#Image_Setting')
	  :pos(w - 26, y - 6):size(30, 30):alpha(200)
	  :image('UI/Image/UICommon/Commonpanel.UITex',18)
	  :hover(function(bIn) this:SetAlpha((bIn and 255) or 200) end)
	  :click(function()
	  	PopupMenu((function()
	  		local t = {}
	  		table.insert(t, {
	  			szOption = _L['filter tong member log message'],
	  			bCheck = true, bChecked = MY_ChatLog.bIgnoreTongMemberLogMsg,
	  			fnAction = function()
	  				MY_ChatLog.bIgnoreTongMemberLogMsg = not MY_ChatLog.bIgnoreTongMemberLogMsg
	  			end,
	  		})
	  		table.insert(t, {
	  			szOption = _L['filter tong online message'],
	  			bCheck = true, bChecked = MY_ChatLog.bIgnoreTongOnlineMsg,
	  			fnAction = function()
	  				MY_ChatLog.bIgnoreTongOnlineMsg = not MY_ChatLog.bIgnoreTongOnlineMsg
	  			end,
	  		})
	  		table.insert(t, {
	  			szOption = _L['rebuild date list'],
	  			fnAction = function()
	  				_C.RebuildDateList({
	  					"MSG_GUILD", "MSG_WHISPER", "MSG_TEAM", "MSG_FRIEND"
	  				}, 300)
	  				_C.UiRedrawLog()
	  			end,
	  		})
	  		return t
	  	end)())
	end)

end

MY.RegisterPanel( "ChatLog", _L["chat log"], _L['Chat'], "ui/Image/button/SystemButton.UITex|43", {255,127,0,200}, {
	OnPanelActive = _C.OnPanelActive,
	OnPanelDeactive = function()
		_C.uiLog = nil
	end
})
