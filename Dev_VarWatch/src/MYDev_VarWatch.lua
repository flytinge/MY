--------------------------------------------
-- @Desc  : UI�¼�ID����
-- @Author: ��һ�� @tinymins
-- @Date  : 2015-02-28 17:37:53
-- @Email : admin@derzh.com
-- @Last Modified by:   ��һ�� @tinymins
-- @Last Modified time: 2015-06-16 18:05:52
--------------------------------------------
local _C = {}
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "Dev_VarWatch/lang/")
local XML_LINE_BREAKER = XML_LINE_BREAKER
local srep, tostring, string2byte = string.rep, tostring, string.byte
local tconcat, tinsert, tremove = table.concat, table.insert, table.remove
local type, next, print, pairs, ipairs = type, next, print, pairs, ipairs
_C.tVarList = {}

local function var2str_x(var, indent, level) -- ֻ����һ��table�Ҳ���������
	local function table_r(var, level, indent)
		local t = {}
		local szType = type(var)
		if szType == "nil" then
			tinsert(t, "nil")
		elseif szType == "number" then
			tinsert(t, tostring(var))
		elseif szType == "string" then
			tinsert(t, string.format("%q", var))
		elseif szType == "boolean" then
			tinsert(t, tostring(var))
		elseif szType == "table" then
			tinsert(t, "{")
			local s_tab_equ = "]="
			if indent then
				s_tab_equ = "] = "
				if not empty(var) then
					tinsert(t, "\n")
				end
			end
			for key, val in pairs(var) do
				if indent then
					tinsert(t, srep(indent, level + 1))
				end
				tinsert(t, "[")
				tinsert(t, tostring(key))
				tinsert(t, s_tab_equ) --"] = "
				tinsert(t, tostring(val))
				tinsert(t, ",")
				if indent then
					tinsert(t, "\n")
				end
			end
			if indent and not empty(var) then
				tinsert(t, srep(indent, level))
			end
			tinsert(t, "}")
		else --if (szType == "userdata") then
			tinsert(t, '"')
			tinsert(t, tostring(var))
			tinsert(t, '"')
		end
		return tconcat(t)
	end
	return table_r(var, level or 0, indent)
end

MY.RegisterPanel(
"Dev_VarWatch", _L["VarWatch"], _L['Development'],
"ui/Image/UICommon/BattleFiled.UITex|7", {255,127,0,200}, {
	OnPanelActive = function(wnd)
		local ui = MY.UI(wnd)
		local x, y = 10, 30
		local w, h = ui:size()
		local nLimit = 10
		
		local tWndEditK = {}
		local tWndEditV = {}
		
		for i = 1, nLimit do
			tWndEditK[i] = ui:append("WndEditBox", "WndEditBox_K" .. i, {
				text = _C.tVarList[i],
				x = x, y = y + (i - 1) * 25,
				w = 150, h = 25,
				color = {255, 255, 255},
				onchange = function(text)
					_C.tVarList[i] = MY.String.Trim(text)
				end,
			}):children("#WndEditBox_K" .. i)
			
			tWndEditV[i] = ui:append("WndEditBox", "WndEditBox_V" .. i, {
				x = x + 150, y = y + (i - 1) * 25,
				w = w - 2 * x - 150, h = 25,
				color = {255, 255, 255},
			}):children("#WndEditBox_V" .. i)
		end
		
		MY.BreatheCall("DEV_VARWATCH", function()
			for i = 1, nLimit do
				local szKey = _C.tVarList[i]
				local hFocus = Station.GetFocusWindow()
				if not empty(szKey) and -- ���Կհ׵�Key
				wnd:GetRoot():IsVisible() and ( -- �����������˾Ͳ�Ҫ������
					not hFocus or (
						not hFocus:GetTreePath():find(tWndEditK[i]:name()) and  -- ����K�༭�е�
						not hFocus:GetTreePath():find(tWndEditV[i]:name()) -- ����V�༭�е�
					)
				) then
					if loadstring then
						oValue = select(2, pcall(loadstring("return " .. szKey)))
					else
						oValue = MY.GetGlobalValue(szKey)
					end
					tWndEditV[i]:text(var2str_x(oValue))
				end
			end
		end)
	end,
	OnPanelDeactive = function()
		MY.BreatheCall("DEV_VARWATCH")
	end,
})
