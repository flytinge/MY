---------------------------------
-- �������
-- by������@˫����@׷����Ӱ
-- ref: �����������Դ�� @haimanchajian.com
---------------------------------
-----------------------------------------------
-- ���غ����ͱ���
-----------------------------------------------
MY = MY or {}
MY.Chat = MY.Chat or {}
MY.Chat.bHookedAlready = false
local _Cache, _L = {}, MY.LoadLangPack()

-- ��������ٳ�����
-- ���츴�Ʋ�����
MY.Chat.RepeatChatLine = function(hTime)
    local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
    if not edit then
        return
    end
    MY.Chat.CopyChatLine(hTime)
    local tMsg = edit:GetTextStruct()
    if #tMsg == 0 then
        return
    end
    local nChannel, szName = EditBox_GetChannel()
    if MY.CanTalk(nChannel) then
        GetClientPlayer().Talk(nChannel, szName or "", tMsg)
        edit:ClearText()
    end
end

-- ��������ʼ��
_Cache.InitEmotion = function()
    if not _Cache.tEmotion then
        local t = { image = {}, animate = {} }
        for i = 1, g_tTable.FaceIcon:GetRowCount() do
            local tLine = g_tTable.FaceIcon:GetRow(i)
            if tLine.szType == "animate" then
                t.animate[tLine.nFrame] = { szCmd = tLine.szCommand, nFrame = tLine.nFrame, dwID = tLine.dwID }
                t.animate[tLine.szCommand] = t.animate[tLine.nFrame]
            else
                t.image[tLine.nFrame] = { szCmd = tLine.szCommand, nFrame = tLine.nFrame, dwID = tLine.dwID }
                t.image[tLine.szCommand] = t.image[tLine.nFrame]
            end
        end
        _Cache.tEmotion = t
    end
end

-- ��ȡ��������б�
-- (table) MY.Chat.GetEmotion()
-- (table) MY.Chat.GetEmotion(szCmd)
-- (table) MY.Chat.GetEmotion(nFrame, bIsAnimate)
MY.Chat.GetEmotion = function(arg0, arg1)
    _Cache.InitEmotion()
    local t
    if type(arg0)=="nil" then
        t = _Cache.tEmotion
    elseif type(arg0)=="string" then
        t = _Cache.tEmotion.image[arg0] or _Cache.tEmotion.animate[arg0]
    elseif type(arg0)=="number" then
        if arg1 then
            t = _Cache.tEmotion.animate[arg0]
        else
            t = _Cache.tEmotion.image[arg1]
        end
    end
    return clone(t)
end

-- ����������
MY.Chat.CopyChatLine = function(hTime)
    local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
    if not edit then
        return
    end
    edit:ClearText()
    local h, i, bBegin = hTime:GetParent(), hTime:GetIndex(), nil
    -- loop
    for i = i + 1, h:GetItemCount() - 1 do
        local p = h:Lookup(i)
        if p:GetType() == "Text" then
            local szName = p:GetName()
            if szName ~= "timelink" and szName ~= "copylink" and szName ~= "msglink" and szName ~= "time" then
                local szText, bEnd = p:GetText(), false
                if StringFindW(szText, "\n") then
                    szText = StringReplaceW(szText, "\n", "")
                    bEnd = true
                end
                if szName == "itemlink" then
                    edit:InsertObj(szText, { type = "item", text = szText, item = p:GetUserData() })
                elseif szName == "iteminfolink" then
                    edit:InsertObj(szText, { type = "iteminfo", text = szText, version = p.nVersion, tabtype = p.dwTabType, index = p.dwIndex })
                elseif string.sub(szName, 1, 8) == "namelink" then
                    if bBegin == nil then
                        bBegin = false
                    end
                    edit:InsertObj(szText, { type = "name", text = szText, name = string.match(szText, "%[(.*)%]") })
                elseif szName == "questlink" then
                    edit:InsertObj(szText, { type = "quest", text = szText, questid = p:GetUserData() })
                elseif szName == "recipelink" then
                    edit:InsertObj(szText, { type = "recipe", text = szText, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
                elseif szName == "enchantlink" then
                    edit:InsertObj(szText, { type = "enchant", text = szText, proid = p.dwProID, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
                elseif szName == "skilllink" then
                    local o = clone(p.skillKey)
                    o.type, o.text = "skill", szText
                    edit:InsertObj(szText, o)
                elseif szName =="skillrecipelink" then
                    edit:InsertObj(szText, { type = "skillrecipe", text = szText, id = p.dwID, level = p.dwLevelD })
                elseif szName =="booklink" then
                    edit:InsertObj(szText, { type = "book", text = szText, tabtype = p.dwTabType, index = p.dwIndex, bookinfo = p.nBookRecipeID, version = p.nVersion })
                elseif szName =="achievementlink" then
                    edit:InsertObj(szText, { type = "achievement", text = szText, id = p.dwID })
                elseif szName =="designationlink" then
                    edit:InsertObj(szText, { type = "designation", text = szText, id = p.dwID, prefix = p.bPrefix })
                elseif szName =="eventlink" then
                    edit:InsertObj(szText, { type = "eventlink", text = szText, name = p.szName, linkinfo = p.szLinkInfo })
                else
                    -- NPC �������⴦��
                    if bBegin == nil then
                        local r, g, b = p:GetFontColor()
                        if r == 255 and g == 150 and b == 0 then
                            bBegin = false
                        end
                    end
                    if bBegin == false then
                        for _, v in ipairs({g_tStrings.STR_TALK_HEAD_WHISPER, g_tStrings.STR_TALK_HEAD_SAY, g_tStrings.STR_TALK_HEAD_SAY1, g_tStrings.STR_TALK_HEAD_SAY2 }) do
                            local nB, nE = StringFindW(szText, v)
                            if nB then
                                szText, bBegin = string.sub(szText, nB + nE), true
                                edit:ClearText()
                            end
                        end
                    end
                    if szText ~= "" and (table.getn(edit:GetTextStruct()) > 0 or szText ~= g_tStrings.STR_FACE) then
                        edit:InsertText(szText)
                    end
                end
                if bEnd then
                    break
                end
            end
        elseif p:GetType() == "Image" then
            local nFrame = p:GetFrame()
            local tEmotion = MY.Chat.GetEmotion(nFrame, false)
            if tEmotion then
                edit:InsertObj(tEmotion.szCmd, { type = "emotion", text = tEmotion.szCmd, id = tEmotion.dwID })
            end
        elseif p:GetType() == "Animate" then
            local nGroup = tonumber(p:GetName())
            if nGroup then
                local tEmotion = MY.Chat.GetEmotion(nGroup, true)
                if tEmotion then
                    edit:InsertObj(tEmotion.szCmd, { type = "emotion", text = tEmotion.szCmd, id = tEmotion.dwID })
                end
            end
        end
    end
    Station.SetFocusWindow(edit)
end

-- ����Item�������
MY.Chat.CopyChatItem = function(p)
    local edit = Station.Lookup("Lowest2/EditBox/Edit_Input")
    if not edit then
        return
    end
    if p:GetType() == "Text" then
        local szText, szName = p:GetText(), p:GetName()
        if szName == "itemlink" then
            edit:InsertObj(szText, { type = "item", text = szText, item = p:GetUserData() })
        elseif szName == "iteminfolink" then
            edit:InsertObj(szText, { type = "iteminfo", text = szText, version = p.nVersion, tabtype = p.dwTabType, index = p.dwIndex })
        elseif string.sub(szName, 1, 8) == "namelink" then
            if bBegin == nil then
                bBegin = false
            end
            edit:InsertObj(szText, { type = "name", text = szText, name = string.match(szText, "%[(.*)%]") })
        elseif szName == "questlink" then
            edit:InsertObj(szText, { type = "quest", text = szText, questid = p:GetUserData() })
        elseif szName == "recipelink" then
            edit:InsertObj(szText, { type = "recipe", text = szText, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
        elseif szName == "enchantlink" then
            edit:InsertObj(szText, { type = "enchant", text = szText, proid = p.dwProID, craftid = p.dwCraftID, recipeid = p.dwRecipeID })
        elseif szName == "skilllink" then
            local o = clone(p.skillKey)
            o.type, o.text = "skill", szText
            edit:InsertObj(szText, o)
        elseif szName =="skillrecipelink" then
            edit:InsertObj(szText, { type = "skillrecipe", text = szText, id = p.dwID, level = p.dwLevelD })
        elseif szName =="booklink" then
            edit:InsertObj(szText, { type = "book", text = szText, tabtype = p.dwTabType, index = p.dwIndex, bookinfo = p.nBookRecipeID, version = p.nVersion })
        elseif szName =="achievementlink" then
            edit:InsertObj(szText, { type = "achievement", text = szText, id = p.dwID })
        elseif szName =="designationlink" then
            edit:InsertObj(szText, { type = "designation", text = szText, id = p.dwID, prefix = p.bPrefix })
        elseif szName =="eventlink" then
            edit:InsertObj(szText, { type = "eventlink", text = szText, name = p.szName, linkinfo = p.szLinkInfo })
        end
        Station.SetFocusWindow(edit)
    end
end

--������Ϣ
MY.Chat.FormatContent = function(szMsg)
    local t = {}
    for n, w in string.gfind(szMsg, "<(%w+)>(.-)</%1>") do
        if w then
            table.insert(t, w)
        end
    end
    -- Output(t)
    local t2 = {}
    for k, v in pairs(t) do
        if not string.find(v, "name=") then
            if string.find(v, "frame=") then
                local n = string.match(v, "frame=(%d+)")
                local tEmotion = MY.Chat.GetEmotion(tonumber(n), false)
                table.insert(t2, {tEmotion.szCmd, {type = "emotion", text = tEmotion.szCmd, id = tEmotion.dwID}})
            elseif string.find(v, "group=") then
                local n = string.match(v, "group=(%d+)")
                local tEmotion = MY.Chat.GetEmotion(tonumber(n), true)
                table.insert(t2, {tEmotion.szCmd, {type = "emotion", text = tEmotion.szCmd, id = tEmotion.dwID}})
            else
                --��ͨ����
                local s = string.match(v, "\"(.*)\"")
                table.insert(t2, {s, {type= "text", text = s}})
            end
        else
            --��Ʒ����
            if string.find(v, "name=\"itemlink\"") then
                local name, userdata = string.match(v,"%[(.-)%].-userdata=(%d+)")
                table.insert(t2, {"["..name.."]", {type = "item", text = name, item = userdata}})
            --��Ʒ��Ϣ
            elseif string.find(v, "name=\"iteminfolink\"") then
                local name, version, tab, index = string.match(v,"%[(.-)%].-script=\"this.nVersion=(%d+)\\%s*this.dwTabType=(%d+)\\%s*this.dwIndex=(%d+)")
                table.insert(t2, {"["..name.."]", {type = "iteminfo", text = name, version = version, tabtype = tab, index = index}})
            --����
            elseif string.find(v, "name=\"namelink_%d+\"") then
                local name = string.match(v,"%[(.-)%]")
                table.insert(t2, {"["..name.."]", {type = "name", text = "["..name.."]", name = name}})
            --����
            elseif string.find(v, "name=\"questlink\"") then
                local name, userdata = string.match(v,"%[(.-)%].-userdata=(%d+)")
                table.insert(t2, {"["..name.."]", {type = "quest", text = name, questid = userdata}})
            --�����
            elseif string.find(v, "name=\"recipelink\"") then
                local name, craft, recipe = string.match(v,"%[(.-)%].-script=\"this.dwCraftID=(%d+)\\%s*this.dwRecipeID=(%d+)")
                table.insert(t2, {"["..name.."]", {type = "recipe", text = name, craftid = craft, recipeid = recipe}})
            --����
            elseif string.find(v, "name=\"skilllink\"") then
                local name, skillinfo = string.match(v,"%[(.-)%].-script=\"this.skillKey=%{(.-)%}")
                local skillKey = {}
                for w in string.gfind(skillinfo, "(.-)%,") do
                    local k, v  = string.match(w, "(.-)=(%w+)")
                    skillKey[k] = v
                end
                table.insert(t2, {"["..name.."]", skillKey})
            --�ƺ�
            elseif string.find(v, "name=\"designationlink\"") then
                local name, id, fix = string.match(v,"%[(.-)%].-script=\"this.dwID=(%d+)\\%s*this.bPrefix=(.-)")
                table.insert(t2, {"["..name.."]", {type = "designation", text = name, id = id, prefix = fix}})
            --�����ؼ�
            elseif string.find(v, "name=\"skillrecipelink\"") then
                local name, id, level = string.match(v,"%[(.-)%].-script=\"this.dwID=(%d+)\\%s*this.dwLevel=(%d+)")
                table.insert(t2, {"["..name.."]", {type = "skillrecipe", text = name, id = id, level = level}})
            --�鼮
            elseif string.find(v, "name=\"booklink\"") then
                local name, version, tab, index, id = string.match(v,"%[(.-)%].-script=\"this.nVersion=(%d+)\\%s*this.dwTabType=(%d+)\\%s*this.dwIndex=(%d+)\\%s*this.nBookRecipeID=(%d+)")
                table.insert(t2, {"["..name.."]", {type = "book", text = name, version = version, tabtype = tab, index = index, bookinfo = id}})
            --�ɾ�
            elseif string.find(v, "name=\"achievementlink\"") then
                local name, id = string.match(v,"%[(.-)%].-script=\"this.dwID=(%d+)")
                table.insert(t2, {"["..name.."]", {type = "achievement", text = name, id = id}})
            --ǿ��
            elseif string.find(v, "name=\"enchantlink\"") then
                local name, pro, craft, recipe = string.match(v,"%[(.-)%].-script=\"this.dwProID=(%d+)\\%s*this.dwCraftID=(%d+)\\%s*this.dwRecipeID=(%d+)")
                table.insert(t2, {"["..name.."]", {type = "enchant", text = name, proid = pro, craftid = craft, recipeid = recipe}})
            --�¼�
            elseif string.find(v, "name=\"eventlink\"") then
                local name, na, info = string.match(v,"%[(.-)%].-script=\"this.szName=\"(.-)\"\\%s*this.szLinkInfo=\"(.-)\"")
                table.insert(t2, {"["..name.."]", {type = "eventlink", text = name, name = na, linkinfo = info or ""}})
            end
        end
    end
    return t2
end

--[[ �ж�ĳ��Ƶ���ܷ���
-- (bool) MY.CanTalk(number nChannel)]]
MY.Chat.CanTalk = function(nChannel)
    for _, v in ipairs({"WHISPER", "TEAM", "RAID", "BATTLE_FIELD", "NEARBY", "TONG", "TONG_ALLIANCE" }) do
        if nChannel == PLAYER_TALK_CHANNEL[v] then
            return true
        end
    end
    return false
end
MY.CanTalk = MY.Chat.CanTalk

-- get channel header
_Cache.tTalkChannelHeader = {
    [PLAYER_TALK_CHANNEL.NEARBY] = "/s ",
    [PLAYER_TALK_CHANNEL.FRIENDS] = "/o ",
    [PLAYER_TALK_CHANNEL.TONG_ALLIANCE] = "/a ",
    [PLAYER_TALK_CHANNEL.TEAM] = "/p ",
    [PLAYER_TALK_CHANNEL.RAID] = "/t ",
    [PLAYER_TALK_CHANNEL.BATTLE_FIELD] = "/b ",
    [PLAYER_TALK_CHANNEL.TONG] = "/g ",
    [PLAYER_TALK_CHANNEL.SENCE] = "/y ",
    [PLAYER_TALK_CHANNEL.FORCE] = "/f ",
    [PLAYER_TALK_CHANNEL.CAMP] = "/c ",
    [PLAYER_TALK_CHANNEL.WORLD] = "/h ",
}
--[[ �л�����Ƶ��
    (void) MY.SwitchChat(number nChannel)
    (void) MY.SwitchChat(string szHeader)
    (void) MY.SwitchChat(string szName)
]]
MY.Chat.SwitchChat = function(nChannel)
    local szHeader = _Cache.tTalkChannelHeader[nChannel]
    if szHeader then
        SwitchChatChannel(szHeader)
    elseif type(nChannel) == "string" then
        if string.sub(nChannel, 1, 1) == "/" then
            SwitchChatChannel(nChannel.." ")
        else
            SwitchChatChannel("/w " .. string.gsub(nChannel,'[%[%]]','') .. " ")
        end
    end
end
MY.SwitchChat = MY.Chat.SwitchChat


-- parse faceicon in talking message
MY.Chat.ParseFaceIcon = function(t)
    local t2 = {}
    for _, v in ipairs(t) do
        if v.type ~= "text" then
            if v.type == "emotion" then
                v.type = "text"
            end
            table.insert(t2, v)
        else
            local nOff, nLen = 1, string.len(v.text)
            while nOff <= nLen do
                local szFace, dwFaceID = nil, nil
                local nPos = StringFindW(v.text, "#", nOff)
                if not nPos then
                    nPos = nLen
                else
                    for i = nPos + 6, nPos + 2, -2 do
                        if i <= nLen then
                            local szTest = string.sub(v.text, nPos, i)
                            if MY.Chat.GetEmotion(szTest) then
                                szFace, dwFaceID = szTest, MY.Chat.GetEmotion(szTest).dwID
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
                    table.insert(t2, { type = "emotion", text = szFace, id = dwFaceID })
                    nOff = nOff + string.len(szFace)
                end
            end
        end
    end
    return t2
end
-- parse name in talking message
MY.Chat.ParseName = function(t)
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
--[[ ������������
-- (void) MY.Talk(string szTarget, string szText[, boolean bNoEscape])
-- (void) MY.Talk([number nChannel, ] string szText[, boolean bNoEscape])
-- szTarget         -- ���ĵ�Ŀ���ɫ��
-- szText               -- �������ݣ������Ϊ���� KPlayer.Talk �� table��
-- nChannel         -- *��ѡ* ����Ƶ����PLAYER_TALK_CHANNLE.*��Ĭ��Ϊ����
-- bNoEscape    -- *��ѡ* ���������������еı���ͼƬ�����֣�Ĭ��Ϊ false
-- bSaveDeny    -- *��ѡ* �������������������ɷ��Ե�Ƶ�����ݣ�Ĭ��Ϊ false
-- �ر�ע�⣺nChannel, szText ���ߵĲ���˳����Ե�����ս��/�Ŷ�����Ƶ�������л�]]
MY.Chat.Talk = function(nChannel, szText, bNoEscape, bSaveDeny)
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
    elseif nChannel == PLAYER_TALK_CHANNEL.LOCAL_SYS then
        return MY.Sysmsg({szText}, '')
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
        tSay = MY.Chat.ParseFaceIcon(tSay)
        tSay = MY.Chat.ParseName(tSay)
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
MY.Talk = MY.Chat.Talk

_Cache.tHookChatFun = {}
--[[ HOOK������ ]]
MY.Chat.HookChatPanel = function(arg0, arg1, arg2)
    local fnBefore, fnAfter, id
    if type(arg0)=="string" then
        id, fnBefore, fnAfter = arg0, arg1, arg2
    elseif type(arg1)=="string" then
        id, fnBefore, fnAfter = arg1, arg0, arg2
    elseif type(arg2)=="string" then
        id, fnBefore, fnAfter = arg2, arg0, arg1
    else
        id, fnBefore, fnAfter = nil, arg0, arg1
    end
    if type(fnBefore)~="function" and type(fnAfter)~="function" then
        return nil
    end
    if id then
        for i=#_Cache.tHookChatFun, 1, -1 do
            if _Cache.tHookChatFun[i].id == id then
                table.remove(_Cache.tHookChatFun, i)
            end
        end
    end
    if fnBefore then
        table.insert(_Cache.tHookChatFun, {fnBefore = fnBefore, fnAfter = fnAfter, id = id})
    end
end
MY.HookChatPanel = MY.Chat.HookChatPanel

_Cache.HookChatPanelHandle = function(h, szMsg)
    -- deal with fnBefore
    for i,handle in ipairs(_Cache.tHookChatFun) do
        -- try to execute fnBefore and get return values
        local result = { pcall(handle.fnBefore, h, szMsg) }
        -- when fnBefore execute succeed
        if result[1] then
            -- remove execute status flag
            table.remove(result, 1)
            if type(result[1])=="string" then
                szMsg = result[1]
            end
            -- remove returned szMsg
            table.remove(result, 1)
        end
        -- the rest is fnAfter param
        _Cache.tHookChatFun[i].param = result
    end
    -- call ori append
    h:_AppendItemFromString_MY(szMsg)
    -- deal with fnAfter
    for i,handle in ipairs(_Cache.tHookChatFun) do
        pcall(handle.fnAfter, h, szMsg, unpack(handle.param))
    end
end
MY.RegisterEvent("CHAT_PANEL_INIT", function ()
    for i = 1, 10 do
        local h = Station.Lookup("Lowest2/ChatPanel" .. i .. "/Wnd_Message", "Handle_Message")
        local ttl = Station.Lookup("Lowest2/ChatPanel" .. i .. "/CheckBox_Title", "Text_TitleName")
        if h and (not ttl or ttl:GetText() ~= g_tStrings.CHANNEL_MENTOR) then
            h._AppendItemFromString_MY = h._AppendItemFromString_MY or h.AppendItemFromString
            h.AppendItemFromString = _Cache.HookChatPanelHandle
        end
    end
end)
MY.RegisterInit(function()
    if Station.Lookup("Lowest2/ChatPanel1/Wnd_Message").bMyHooked then
        MY.Chat.bHookedAlready = true
    else
        MY.Chat.bHookedAlready = false
    end
    Station.Lookup("Lowest2/ChatPanel1/Wnd_Message").bMyHooked = true   
end)