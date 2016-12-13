--------------------------------------------
-- @Desc  : ���츨��
-- @Author: ��һ�� @tinymins
-- @Date  : 2016-02-5 11:35:53
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2016-12-13 10:40:35
--------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_ChatCopy/lang/")
MY_ChatCopy = {}
MY_ChatCopy.bChatCopy = true
MY_ChatCopy.bChatTime = true
MY_ChatCopy.eChatTime = "HOUR_MIN_SEC"
MY_ChatCopy.bChatCopyAlwaysShowMask = false
MY_ChatCopy.bChatCopyAlwaysWhite = false
MY_ChatCopy.bChatCopyNoCopySysmsg = false
RegisterCustomData("MY_ChatCopy.bChatCopy")
RegisterCustomData("MY_ChatCopy.bChatTime")
RegisterCustomData("MY_ChatCopy.eChatTime")
RegisterCustomData("MY_ChatCopy.bChatCopyAlwaysShowMask")
RegisterCustomData("MY_ChatCopy.bChatCopyAlwaysWhite")
RegisterCustomData("MY_ChatCopy.bChatCopyNoCopySysmsg")

-- hook chat panel
MY.HookChatPanel("MY_ChatCopy", function(h, szChannel, szMsg, dwTime, nR, nG, nB, dwTime, dwTalkerID, szName)
	return szMsg, h:GetItemCount()
end, function(h, i, szChannel, szMsg, dwTime, nR, nG, nB)
	if szMsg and i and h:GetItemCount() > i and (MY_ChatCopy.bChatTime or MY_ChatCopy.bChatCopy) then
		-- chat time
		-- check if timestrap can insert
		if MY_ChatCopy.bChatCopyNoCopySysmsg and szChannel == "SYS_MSG" then
			return
		end
		-- create timestrap text
		local szTime = ""
		if MY_ChatCopy.bChatCopy and (MY_ChatCopy.bChatCopyAlwaysShowMask or not MY_ChatCopy.bChatTime) then
			local _r, _g, _b = nR, nG, nB
			if MY_ChatCopy.bChatCopyAlwaysWhite then
				_r, _g, _b = 255, 255, 255
			end
			szTime = MY.Chat.GetCopyLinkText(_L[" * "], { r = _r, g = _g, b = _b })
		elseif MY_ChatCopy.bChatCopyAlwaysWhite then
			nR, nG, nB = 255, 255, 255
		end
		if MY_ChatCopy.bChatTime then
			if MY_ChatCopy.eChatTime == "HOUR_MIN_SEC" then
				szTime = szTime .. MY.Chat.GetTimeLinkText({r = nR, g = nG, b = nB, f = 10, s = "[hh:mm:ss]"}, dwTime)
			else
				szTime = szTime .. MY.Chat.GetTimeLinkText({r = nR, g = nG, b = nB, f = 10, s = "[hh:mm]"}, dwTime)
			end
		end
		-- insert timestrap text
		h:InsertItemFromString(i, false, szTime)
	end
end)
