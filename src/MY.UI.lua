MY = MY or {}
local _MY = {
    szIniFileEditBox = "Interface\\MY\\ui\\WndEditBox.ini",
    szIniFileButton = "Interface\\MY\\ui\\WndButton.ini",
    szIniFileCheckBox = "Interface\\MY\\ui\\WndCheckBox.ini",
    szIniFileMainPanel = "Interface\\MY\\ui\\MainPanel.ini",
}
---------------------------------------------------------------------
-- 本地的 UI 组件对象
---------------------------------------------------------------------
-------------------------------------
-- UI object class
-------------------------------------
_MY.UI = class()

-- 不会玩元表 (╯‵□′)╯︵┻━┻
-- -- 设置元表，这样可以当作table调用，其效果相当于 .eles[i].raw
-- setmetatable(_MY.UI, {  __call = function(me, ...) return me:ctor(...) end, __index = function(t, k) 
    -- if type(k) == "number" then
        -- return t.eles[k].raw
    -- elseif k=="new" then
        -- return t['ctor']
    -- end
-- end
-- , __metatable = true 
-- })

-----------------------------------------------------------
-- my ui common functions
-----------------------------------------------------------
-- 获取一个窗体的所有子元素
local GetChildren = function(root)
    local stack = { root }  -- 初始栈
    local children = {}     -- 保存所有子元素 szTreePath => element 键值对
    while #stack > 0 do     -- 循环直到栈空
        --### 弹栈: 弹出栈顶元素
        local raw = stack[#stack]
        table.remove(stack, #stack)
        -- 将当前弹出的元素加入子元素表
        children[table.concat({ raw:GetTreePath() })] = raw
        -- 如果有Handle则将所有Handle子元素加入子元素表
        local status, handle = pcall(function() return raw:Lookup('','') end) -- raw可能没有Lookup方法 用pcall包裹
        if status and handle then
            children[table.concat({ handle:GetTreePath(), '/Handle' })] = handle
            for i = 0, handle:GetItemCount() - 1, 1 do
                children[table.concat({ handle:Lookup(i):GetTreePath() })] = handle:Lookup(i)
            end
        end
        --### 压栈: 将刚刚弹栈的元素的所有子窗体压栈
        local status, sub_raw = pcall(function() return raw:GetFirstChild() end) -- raw可能没有GetFirstChild方法 用pcall包裹
        while status and sub_raw do
            table.insert(stack, sub_raw)
            sub_raw = sub_raw:GetNext()
        end
    end
    -- 因为是求子元素 所以移除第一个压栈的元素（父元素）
    children[table.concat({ root:GetTreePath() })] = nil
    return children
end

-----------------------------------------------------------
-- my ui selectors -- same as jQuery -- by tinymins --
-----------------------------------------------------------
--
-- self.ele       : ui elements table
-- selt.ele[].raw : ui element itself    -- common functions will do with this
-- self.ele[].txt : ui element text box  -- functions like Text() will do with this
-- self.ele[].img : ui element image box -- functions like LoadImage() will do with this
--
-- ui object creator 
-- same as jQuery.$()
function _MY.UI:ctor(raw, tab)
    if type(raw)=="table" and type(raw.eles)=="table" then
        self.eles = raw.eles
    else
        self.eles = self.eles or {}
        -- farmat raw
        if type(raw)=="string" then raw = Station.Lookup(raw) end
        -- format tab
        if type(tab)~="table" then tab = {} end
        local szType = raw:GetType()
        if not tab.txt and szType == "Text" then tab.txt = raw end
        if not tab.img and szType == "Image" then tab.img = raw end
        if not tab.chk and szType == "WndCheckBox" then tab.chk = raw end
        if not tab.edt and szType == "WndEdit" then tab.edt = raw end
        if not tab.sdw and szType == "Shadow" then tab.sdw = raw end
        if string.sub(szType, 1, 3) == "Wnd" then tab.wnd = raw else tab.itm = raw end
        if raw then table.insert( self.eles, { raw = raw, txt = tab.txt, img = tab.img, chk = tab.chk, edt = tab.edt, wnd = tab.wnd, itm = tab.itm, sdw = tab.sdw } ) end
    end
    return self
end

-- clone
-- clone and return a new class
function _MY.UI:clone(eles)
    eles = eles or self.eles
    return _MY.UI.new({eles = eles})
end

-- conv raw to eles array
function _MY.UI:raw2ele(raw, tab)
    -- format tab
    if type(tab)~="table" then tab = {} end
    local szType = raw:GetType()
    if not tab.txt and szType == "Text" then tab.txt = raw end
    if not tab.img and szType == "Image" then tab.img = raw end
    if not tab.chk and szType == "WndCheckBox" then tab.chk = raw end
    if not tab.edt and szType == "WndEdit" then tab.edt = raw end
        if not tab.sdw and szType == "Shadow" then tab.sdw = raw end
    if string.sub(szType, 1, 3) == "Wnd" then tab.wnd = raw else tab.itm = raw end
    return { raw = raw, txt = tab.txt, img = tab.img, chk = tab.chk, edt = tab.edt, wnd = tab.wnd, itm = tab.itm, sdw = tab.sdw }
end

-- add a ele to object
-- same as jQuery.add()
function _MY.UI:add(raw, tab)
    local eles = self.eles
    -- farmat raw
    if type(raw)=="string" then raw = Station.Lookup(raw) end
    -- insert into eles
    if raw then table.insert( eles, self:raw2ele(raw, tab) ) end
    return self:clone(eles)
end

-- delete elements from object
-- same as jQuery.not()
function _MY.UI:del(raw)
    local eles = self.eles
    if type(raw) == "string" then
        -- delete ele those id/class fits filter:raw
        if string.sub(raw, 1, 1) == "#" then
            raw = string.sub(raw, 2)
            for i = #eles, 1, -1 do
                if eles[i].raw:GetName() == raw then
                    table.remove(eles, i)
                end
            end
        elseif string.sub(raw, 1, 1) == "." then
            raw = string.sub(raw, 2)
            for i = #eles, 1, -1 do
                if eles[i].raw:GetType() == raw then
                    table.remove(eles, i)
                end
            end
        end
    else
        -- delete ele those treepath is the same as raw
        raw = table.concat({ raw:GetTreePath() })
        for i = #eles, 1, -1 do
            if table.concat({ eles[i].raw:GetTreePath() }) == raw then
                table.remove(eles, i)
            end
        end
    end
    return self:clone(eles)
end

-- filter elements from object
-- same as jQuery.filter()
function _MY.UI:filter(raw)
    local eles = self.eles
    if type(raw) == "string" then
        -- delete ele those id/class not fits filter:raw
        if string.sub(raw, 1, 1) == "#" then
            raw = string.sub(raw, 2)
            for i = #eles, 1, -1 do
                if eles[i].raw:GetName() ~= raw then
                    table.remove(eles, i)
                end
            end
        elseif string.sub(raw, 1, 1) == "." then
            raw = string.sub(raw, 2)
            for i = #eles, 1, -1 do
                if eles[i].raw:GetType() ~= raw then
                    table.remove(eles, i)
                end
            end
        end
    elseif type(raw)=="nil" then
        return self
    else
        -- delete ele those treepath is not the same as raw
        raw = table.concat({ raw:GetTreePath() })
        for i = #eles, 1, -1 do
            if table.concat({ eles[i].raw:GetTreePath() }) ~= raw then
                table.remove(eles, i)
            end
        end
    end
    return self:clone(eles)
end

-- get parent
-- same as jQuery.parent()
function _MY.UI:parent()
    local parent = {}
    for _, ele in pairs(self.eles) do
        parent[ele.raw:GetParent():GetTreePath()] = ele.raw:GetParent()
    end
    local eles = {}
    for _, raw in pairs(parent) do
        -- insert into eles
        table.insert( eles, self:raw2ele(raw) )
    end
    return self:clone(eles)
end

-- get child
-- same as jQuery.child()
function _MY.UI:child()
    local child = {}
    for _, ele in pairs(self.eles) do
        -- 子handle
        local status, handle = pcall(function() return ele.raw.Lookup('','') end) -- raw可能没有Lookup方法 用pcall包裹
        if status and handle then
            child[handle:GetTreePath()] = handle
        end
        -- 子窗体
        local status, sub_raw = pcall(function() return ele.raw:GetFirstChild() end) -- raw可能没有GetFirstChild方法 用pcall包裹
        while status and sub_raw do
            child[sub_raw:GetTreePath()] = sub_raw
            sub_raw = sub_raw:GetNext()
        end
    end
    local eles = {}
    for _, raw in pairs(child) do
        -- insert into eles
        table.insert( eles, self:raw2ele(raw) )
    end
    return self:clone(eles)
end

-- get all children
-- same as jQuery.children(filter)
function _MY.UI:children(filter)
    local children = {}
    for _, ele in pairs(self.eles) do
        for szTreePath, raw in pairs(GetChildren(ele.raw)) do
            children[szTreePath] = raw
        end
    end
    local eles = {}
    for _, raw in pairs(children) do
        -- insert into eles
        table.insert( eles, self:raw2ele(raw) )
    end
    return self:clone(eles):filter(filter)
end

-- find ele
-- same as jQuery.find()
function _MY.UI:find(filter)
    return self:children():filter(filter)
end

-- each
-- same as jQuery.each(function(){})
function _MY.UI:each(fn)
    local eles = self.eles
    for _, ele in pairs(eles) do
        pcall(fn, ele.raw)
    end
    return self
end

-- eq
-- same as jQuery.eq(pos)
function _MY.UI:eq(pos)
    if pos then
        return self:slice(pos,pos)
    end
    return self
end

-- first
-- same as jQuery.first()
function _MY.UI:first()
    return self:slice(1,1)
end

-- last
-- same as jQuery.last()
function _MY.UI:last()
    return self:slice(-1,-1)
end

-- slice -- index starts from 1
-- same as jQuery.slice(selector, pos)
function _MY.UI:slice(startpos, endpos)
    local eles = self.eles
    endpos = endpos or #eles
    if endpos < 0 then endpos = #eles + endpos + 1 end
    for i = #eles, endpos + 1, -1 do
        table.remove(eles)
    end
    if startpos < 0 then startpos = #eles + startpos + 1 end
    for i = startpos, 2, -1 do
        table.remove(eles, 1)
    end
    return self:clone(eles)
end

-- get raw
-- same as jQuery[index]
function _MY.UI:raw(index)
    local eles = self.eles
    if index < 0 then index = #eles + index + 1 end
    if index > 0 and index <= #eles then return eles[index].raw end
end

-----------------------------------------------------------
-- my ui opreation -- same as jQuery -- by tinymins --
-----------------------------------------------------------

-- remove
-- same as jQuery.remove()
function _MY.UI:remove()
    for _, ele in pairs(self.eles) do
        pcall(function() ele.fnDestroy(ele.raw) end)
        if ele.raw:GetType() == "WndFrame" then
            Wnd.CloseWindow(self.raw)
        elseif string.sub(ele.raw:GetType(), 1, 3) == "Wnd" then
            ele.raw:Destroy()
        else
            ele.raw:GetParent():RemoveItem(ele.raw:GetIndex())
        end
    end
    self.eles = {}
    return self
end

-----------------------------------------------------------
-- my ui property visitors
-----------------------------------------------------------

-- show/hide eles
function _MY.UI:toggle(bShow)
    for _, ele in pairs(self.eles) do
        pcall(function() if bShow == false or (not bShow and ele.raw:IsVisible()) then ele.raw:Hide() else ele.raw:Show() end end)
    end
    return self
end

-- get/set ui object text
function _MY.UI:text(szText)
    if szText then
        for _, ele in pairs(self.eles) do
            pcall(function() ele.raw:SetText(szText) end)
        end
        return self
    else
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, err = pcall(function() return ele.raw:GetText() end)
        -- if succeed then return its name
        if status then return err else MY.Debug(err,'ERROR _MY.UI:text' ,3) return nil end
    end
end

-- get/set ui object name
function _MY.UI:name(szText)
    if szText then -- set name
        for _, ele in pairs(self.eles) do
            pcall(function() ele.raw:SetName(szText) end)
        end
        return self
    else -- get
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, err = pcall(function() return ele.raw:GetName() end)
        -- if succeed then return its name
        if status then return err else MY.Debug(err,'ERROR _MY.UI:name' ,3) return nil end
    end
end

-- get/set ui alpha
function _MY.UI:alpha(nAlpha)
    if nAlpha then -- set name
        for _, ele in pairs(self.eles) do
            pcall(function() ele.raw:SetAlpha(nAlpha) end)
        end
        return self
    else -- get
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, err = pcall(function() return ele.raw:GetAlpha() end)
        -- if succeed then return its name
        if status then return err else MY.Debug(err,'ERROR _MY.UI:alpha' ,3) return nil end
    end
end


-- (number) Instance:font()
-- (self) Instance:font(number nFont)
function _MY.UI:font(nFont)
    if nFont then-- set name
        for _, ele in pairs(self.eles) do
            pcall(function() ele.raw:SetFontScheme(nFont) end)
        end
        return self
    else -- get
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, err = pcall(function() return ele.raw:GetFontScheme() end)
        -- if succeed then return its name
        if status then return err else MY.Debug(err,'ERROR _MY.UI:font' ,3) return nil end
    end
end

-- (number, number, number) Instance:color()
-- (self) Instance:color(number nRed, number nGreen, number nBlue)
function _MY.UI:color(nRed, nGreen, nBlue)
    if type(nRed) == "table" then
        nBlue = nRed[3]
        nGreen = nRed[2]
        nRed = nRed[1]
    end
    if nBlue then
        for _, ele in pairs(self.eles) do
            pcall(function() ele.sdw:SetColorRGB(nRed, nGreen, nBlue) end)
            pcall(function() (ele.edt or ele.txt):SetFontColor(nRed, nGreen, nBlue) end)
        end
        return self
    else -- get
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, r,g,b = pcall(function() if ele.sdw then return ele.sdw:GetColorRGB() else return (ele.edt or ele.txt):GetFontColor() end end)
        -- if succeed then return its name
        if status then return r,g,b else MY.Debug(err,'ERROR _MY.UI:font' ,3) return nil end
    end
end
-----------------------------------------------------------
-- my ui events handle
-----------------------------------------------------------

--[[ click 鼠标单击事件
    same as jQuery.click()
    :click(fnAction) 绑定
    :click()         触发
]]
function _MY.UI:click(fn)
    for _, ele in pairs(self.eles) do
        if fn then
            if ele.wnd then ele.wnd.OnLButtonClick = fn end
            if ele.itm then ele.itm.OnItemLButtonClick = fn end
        else
            if ele.wnd then pcall(ele.wnd.OnLButtonClick) end
            if ele.itm then pcall(ele.wnd.OnItemLButtonClick) end
        end
    end
    return self
end

--[[ hover 鼠标悬停事件
    same as jQuery.hover()
    :hover(fnHover[, fnLeave]) 绑定
]]
function _MY.UI:hover(fnHover, fnLeave)
    fnLeave = fnLeave or fnHover
    if fnHover then
        for _, ele in pairs(self.eles) do
            if ele.wnd then ele.wnd.OnMouseEnter = function() fnHover(true) end end
            if ele.wnd then ele.wnd.OnMouseLeave = function() fnLeave(false) end end
            if ele.itm then ele.itm.OnItemMouseEnter = function() fnHover(true) end end
            if ele.itm then ele.itm.OnItemMouseLeave = function() fnLeave(false) end end
        end
    end
    return self
end

--[[ check 复选框状态变化
    :check(fnOnCheckBoxCheck[, fnOnCheckBoxUncheck]) 绑定
    :check()                返回是否已勾选
    :check(bool bChecked)   勾选/取消勾选
]]
function _MY.UI:check(fnCheck, fnUncheck)
    fnUncheck = fnUncheck or fnCheck
    if type(fnCheck)=="function" then
        for _, ele in pairs(self.eles) do
            if ele.chk then ele.chk.OnCheckBoxCheck = function() fnCheck(true) end end
            if ele.chk then ele.chk.OnCheckBoxUncheck = function() fnUncheck(false) end end
        end
        return self
    elseif type(fnCheck) == "boolean" then
        for _, ele in pairs(self.eles) do
            if ele.chk then ele.chk:Check(fnCheck) end
        end
        return self
    else
        -- select the first item
        local ele = self.eles[1]
        -- try to get its name
        local status, err = pcall(function() return ele.chk:IsCheckBoxChecked() end)
        -- if succeed then return its name
        if status then return err else MY.Debug(err,'ERROR _MY.UI:check' ,3) return nil end
    end
end

--[[ change 输入框文字变化
    :change(fnOnEditChanged) 绑定
    :change()   调用处理函数
]]
function _MY.UI:change(fnOnEditChanged)
    if fnOnEditChanged then
        for _, ele in pairs(self.eles) do
            if ele.edt then ele.edt.OnEditChanged = fnOnEditChanged end
        end
        return self
    else
        for _, ele in pairs(self.eles) do
            if ele.edt then pcall(ele.edt.OnEditChanged) end
        end
        return self
    end
end

-- OnGetFocus 获取焦点

-----------------------------------------------------------
-- MY.UI
-----------------------------------------------------------

MY.UI = MY.UI or {}

-- 设置元表，这样可以当作函数调用，其效果相当于 MY.UI.Fetch
setmetatable(MY.UI, { __call = function(me, ...) return me.Fetch(...) end, __metatable = true })

--[[ 构造函数 类似jQuery: $(selector) ]]
MY.UI.Fetch = function(selector, tab) return _MY.UI.new(selector, tab) end

-- 打开浏览器
MY.UI.OpenInternetExplorer = function(szAddr, bDisableSound)
    local nIndex, nLast = nil, nil
    for i = 1, 10, 1 do
        if not _MY.UI.IsInternetExplorerOpened(i) then
            nIndex = i
            break
        elseif not nLast then
            nLast = i
        end
    end
    if not nIndex then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.MSG_OPEN_TOO_MANY)
        return nil
    end
    local x, y = _MY.UI.IE_GetNewIEFramePos()
    local frame = Wnd.OpenWindow("InternetExplorer", "IE"..nIndex)
    frame.bIE = true
    frame.nIndex = nIndex

    frame:BringToTop()
    if nLast then
        frame:SetAbsPos(x, y)
        frame:CorrectPos()
        frame.x = x
        frame.y = y
    else
        frame:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
        frame.x, frame.y = frame:GetAbsPos()
    end
    local webPage = frame:Lookup("WebPage_Page")
    if szAddr then
        webPage:Navigate(szAddr)
    end
    Station.SetFocusWindow(webPage)
    if not bDisableSound then
        PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
    end
    return webPage
end
-- 判断浏览器是否已开启
_MY.UI.IsInternetExplorerOpened = function(nIndex)
    local frame = Station.Lookup("Topmost/IE"..nIndex)
    if frame and frame:IsVisible() then
        return true
    end
    return false
end
-- 获取浏览器绝对位置
_MY.UI.IE_GetNewIEFramePos = function()
    local nLastTime = 0
    local nLastIndex = nil
    for i = 1, 10, 1 do
        local frame = Station.Lookup("Topmost/IE"..i)
        if frame and frame:IsVisible() then
            if frame.nOpenTime > nLastTime then
                nLastTime = frame.nOpenTime
                nLastIndex = i
            end
        end
    end
    if nLastIndex then
        local frame = Station.Lookup("Topmost/IE"..nLastIndex)
        x, y = frame:GetAbsPos()
        local wC, hC = Station.GetClientSize()
        if x + 890 <= wC and y + 630 <= hC then
            return x + 30, y + 30
        end
    end
    return 40, 40
end

--[[ 添加复选框
    MY.UI.AddCheckBox(szPanelName,szName,x,y,szText,col,bChecked)
    szPanelName 要添加复选框的标签页ID
    szName      复选框名称
    x,y         复选框坐标
    szText      复选框标题
    col         标题颜色rgb
    bChecked    复选框是否勾选
 ]]
MY.UI.AddCheckBox = function(szPanelName,szName,x,y,szText,col,bChecked)
	local fx = Wnd.OpenWindow(_MY.szIniFileCheckBox, "aCheckBox")
    local item
	if fx then    
		item = fx:Lookup("WndCheckBox")
		if item then
			item:ChangeRelation(MY.GetFrame():Lookup("Window_Main/MainPanel_"..szPanelName), true, true)
			item:SetName(szName)
			item:Check(bChecked)
			item:SetRelPos(x,y)
			item:Lookup("","CheckBox_Text"):SetText(szText)
			item:Lookup("","CheckBox_Text"):SetFontScheme(18)
			item:Lookup("","CheckBox_Text"):SetFontColor(unpack(col))
		end
	end
	Wnd.CloseWindow(fx)
    return MY.UI(item)
end
--[[ 添加按钮
    MY.UI.AddButton(szPanelName,szName,x,y,szText,col)
    szPanelName 要添加按钮的标签页ID
    szName      按钮名称
    x,y         按钮坐标
    szText      按钮标题
    col         标题颜色rgb
 ]]
MY.UI.AddButton = function(szPanelName,szName,x,y,szText,col)
	local fx = Wnd.OpenWindow(_MY.szIniFileButton, "aWndButton")
    local item
	if fx then    
		item = fx:Lookup("WndButton")
		if item then
			item:ChangeRelation(MY.GetFrame():Lookup("Window_Main/MainPanel_"..szPanelName), true, true)
			item:SetName(szName)
			item:SetRelPos(x,y)
			item:Lookup("","Text_Default"):SetText(szText)
			item:Lookup("","Text_Default"):SetFontScheme(18)
			item:Lookup("","Text_Default"):SetFontColor(unpack(col))
		end
	end
	Wnd.CloseWindow(fx)
    return MY.UI(item)
end
--[[ 添加文本输入框
    MY.UI.AddButton(szPanelName,szName,x,y,w,h,bMultiLine)
    szPanelName 要添加文本输入框的标签页ID
    szName      文本输入框名称
    x,y         文本输入框坐标
    w,h         文本输入框大小
    szText      文本框文本
    bMultiLine  文本框是否允许多行
 ]]
MY.UI.AddEdit = function(szPanelName,szName,x,y,w,h,szText,bMultiLine)
	local fx = Wnd.OpenWindow(_MY.szIniFileEditBox, "aEditBox")
    local item
	if fx then	
		item = fx:Lookup("WndEdit")
		if item then
			item:ChangeRelation(MY.GetFrame():Lookup("Window_Main/MainPanel_"..szPanelName), true, true)
			item:SetName("WndEdit"..szName)
            item:SetSize(w,h)
			item:Lookup("Edit_Text"):SetSize(w-8,h-4)
			item:Lookup("Edit_Text"):SetMultiLine(bMultiLine)
			item:Lookup("Edit_Text"):SetText(szText or '')
			item:Lookup("Edit_Text"):SetName(szName)
			item:Lookup("","Edit_Image"):SetSize(w,h)
			item:SetRelPos(x,y)
		end
	end 
    Wnd.CloseWindow(fx)
    return MY.UI(item, { edt = item:Lookup(szName) })
end
--[[ 寻找指定panel下的指定id的控件 ]]
MY.UI.Lookup = function(szPanelName, szLookupName)
    return MY.UI(MY.GetFrame():Lookup("Window_Main/MainPanel_"..szPanelName)):find('#'..szLookupName)
end

MY.Debug("ui plugins inited!\n",nil,1)