--------------------------------------------
-- @Desc  : ������� - �ַ�������
-- @Author: ���� @˫���� @׷����Ӱ
-- @Date  : 2015-01-25 15:35:26
-- @Email : admin@derzh.com
-- @Last Modified by:   ��һ�� @tinymins
-- @Last Modified time: 2015-05-29 10:06:20
-- @Ref: �����������Դ�� @haimanchajian.com
--------------------------------------------
------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
------------------------------------------------------------------------
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local tinsert, tremove, tconcat = table.insert, table.remove, table.concat
local ssub, slen, schar, srep, sbyte, sformat, sgsub =
      string.sub, string.len, string.char, string.rep, string.byte, string.format, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local floor, mmin, mmax, mceil = math.floor, math.min, math.max, math.ceil
local GetClientPlayer, GetPlayer, GetNpc, GetClientTeam, UI_GetClientPlayerID = GetClientPlayer, GetPlayer, GetNpc, GetClientTeam, UI_GetClientPlayerID
local setmetatable = setmetatable
--------------------------------------------
-- ���غ����ͱ���
--------------------------------------------
MY = MY or {}
MY.String = MY.String or {}

-- �ָ��ַ���
-- (table) MY.String.Split(string szText, string szSpliter, bool bIgnoreEmptyPart)
-- szText           ԭʼ�ַ���
-- szSpliter        �ָ���
-- bIgnoreEmptyPart �Ƿ���Կ��ַ�������"123;234;"��";"�ֳ�{"123","234"}����{"123","234",""}
MY.String.Split = function(szText, szSep, bIgnoreEmptyPart)
	local nOff, tResult, szPart = 1, {}
	while true do
		local nEnd = StringFindW(szText, szSep, nOff)
		if not nEnd then
			szPart = string.sub(szText, nOff, string.len(szText))
			if not bIgnoreEmptyPart or szPart ~= "" then
				table.insert(tResult, szPart)
			end
			break
		else
			szPart = string.sub(szText, nOff, nEnd - 1)
			if not bIgnoreEmptyPart or szPart ~= "" then
				table.insert(tResult, szPart)
			end
			nOff = nEnd + string.len(szSep)
		end
	end
	return tResult
end

-- ת��������ʽ�����ַ�
-- (string) MY.String.PatternEscape(string szText)
MY.String.PatternEscape = function(s) return (string.gsub(s, '([%(%)%.%%%+%-%*%?%[%^%$%]])', '%%%1')) end

-- ����ַ�����β�Ŀհ��ַ�
-- (string) MY.String.Trim(string szText)
MY.String.Trim = function(szText)
	if not szText or szText == "" then
		return ""
	end
	return (string.gsub(szText, "^%s*(.-)%s*$", "%1"))
end

-- ת��Ϊ URL ����
-- (string) MY.String.UrlEncode(string szText)
MY.String.UrlEncode = function(szText)
	return szText:gsub("([^0-9a-zA-Z ])", function (c) return string.format ("%%%02X", string.byte(c)) end):gsub(" ", "+")
end

-- ���� URL ����
-- (string) MY.String.UrlDecode(string szText)
MY.String.UrlDecode = function(szText)
	return szText:gsub("+", " "):gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
end

MY.String.LenW = function(str)
	return wstring.len(str)
end

MY.String.SubW = function(str,s,e)
	if s < 0 then
		s = wstring.len(str) + s
	end
	if e < 0 then
		e = wstring.len(str) + e
	end
	return wstring.sub(str, s, e)
end

MY.String.SimpleEcrypt = function(szText)
	return szText:gsub('.', function (c) return string.format ("%02X", (string.byte(c) + 13) % 256) end):gsub(" ", "+")
end

local m_simpleMatchCache = setmetatable({}, { __mode = "v" })
function MY.String.SimpleMatch(szText, szFind, bDistinctCase)
    if not bDistinctCase then
        szFind = StringLowerW(szFind)
        szText = StringLowerW(szText)
    end
	local tFind = m_simpleMatchCache[szFind]
	if not tFind then
		tFind = {}
		for _, szKeyWordsLine in ipairs(MY.String.Split(szFind, ';', true)) do
			local tKeyWordsLine = {}
			for _, szKeyWords in ipairs(MY.String.Split(szKeyWordsLine, ',', true)) do
				local tKeyWords = {}
				for _, szKeyWord in ipairs(MY.String.Split(szKeyWords, '|', true)) do
					tinsert(tKeyWords, szKeyWord)
				end
				tinsert(tKeyWordsLine, tKeyWords)
			end
			tinsert(tFind, tKeyWordsLine)
		end
		m_simpleMatchCache[szFind] = tFind
	end
	local me = GetClientPlayer()
	if me then
		szFind = szFind:gsub("$zj", GetClientPlayer().szName)
		local szTongName = ""
		local tong = GetTongClient()
		if tong and me.dwTongID ~= 0 then
			szTongName = tong.ApplyGetTongName(me.dwTongID) or ""
		end
		szFind = szFind:gsub("$bh", szTongName)
		szFind = szFind:gsub("$gh", szTongName)
	end
	-- 10|ʮ��,Ѫս���|XZTC,!С��������,!�������;��ս
	local bKeyWordsLine = false
	for _, tKeyWordsLine in ipairs(tFind) do         -- ����һ������
		-- 10|ʮ��,Ѫս���|XZTC,!С��������,!�������
		local bKeyWords = true
		for _, tKeyWords in ipairs(tKeyWordsLine) do -- ����ȫ������
			-- 10|ʮ��
			local bKeyWord = false
			for _, szKeyWord in ipairs(tKeyWords) do  -- ����һ������
				-- szKeyWord = MY.String.PatternEscape(szKeyWord) -- ����wstring��Escape���ݱ�
				if szKeyWord:sub(1, 1) == "!" then              -- !С��������
					szKeyWord = szKeyWord:sub(2)
					if not wstring.find(szText, szKeyWord) then
						bKeyWord = true
					end
				else                                                    -- ʮ��   -- 10
					if wstring.find(szText, szKeyWord) then
						bKeyWord = true
					end
				end
				if bKeyWord then
					break
				end
			end
			bKeyWords = bKeyWords and bKeyWord
			if not bKeyWords then
				break
			end
		end
		bKeyWordsLine = bKeyWordsLine or bKeyWords
		if bKeyWordsLine then
			break
		end
	end
	return bKeyWordsLine
end
