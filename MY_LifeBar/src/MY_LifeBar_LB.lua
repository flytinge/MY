---------------------------------------------------
-- @Author: Emine Zhai (root@derzh.com)
-- @Date:   2018-03-19 12:50:01
-- @Last Modified by:   Emine Zhai (root@derzh.com)
-- @Last Modified time: 2018-03-20 11:02:42
---------------------------------------------------
-----------------------------------------------------------------------------------------
-- these global functions are accessed all the time by the event handler
-- so caching them is worth the effort
-----------------------------------------------------------------------------------------
local setmetatable = setmetatable
local ipairs, pairs, next, pcall = ipairs, pairs, next, pcall
local sub, len, format, rep = string.sub, string.len, string.format, string.rep
local find, byte, char, gsub = string.find, string.byte, string.char, string.gsub
local type, tonumber, tostring = type, tonumber, tostring
local floor, min, max, ceil = math.floor, math.min, math.max, math.ceil
local huge, pi, sin, cos, tan = math.huge, math.pi, math.sin, math.cos, math.tan
local insert, remove, concat, sort = table.insert, table.remove, table.concat, table.sort
local pack, unpack = table.pack or function(...) return {...} end, table.unpack or unpack
-- jx3 apis caching
local wsub, wlen, wfind = wstring.sub, wstring.len, wstring.find
local GetTime, GetLogicFrameCount = GetTime, GetLogicFrameCount
local GetClientPlayer, GetPlayer, GetNpc = GetClientPlayer, GetPlayer, GetNpc
local GetClientTeam, UI_GetClientPlayerID = GetClientTeam, UI_GetClientPlayerID
local IsNil, IsNumber, IsFunction = MY.IsNil, MY.IsNumber, MY.IsFunction
local IsBoolean, IsString, IsTable = MY.IsBoolean, MY.IsString, MY.IsTable
-----------------------------------------------------------------------------------------
local Config = MY_LifeBar_Config
if not Config then
    return
end

local function GetConfigValue(key, relation, force)
	local cfg, value = Config[key][relation]
	if force == 'Npc' or force == 'Player' then
		value = cfg[force]
	else
		if cfg.DifferentiateForce then
			value = cfg[force]
		end
		if value == nil then
			value = Config[key][relation]["Player"]
		end
	end
	return value
end
-----------------------------------------------------------------------------------------
local OT_STATE = {
	START_SKILL   = 1,  -- ��ʼ���ܶ���(��ʾ�߿�)
	START_PREPARE = 2,  -- ��ʼ����(��ʾ�߿�)
	START_CHANNEL = 3,  -- ��ʼ�����(��ʾ�߿�)
	ON_SKILL      = 4,  -- ���ڼ��ܶ���(��Ҫÿ֡��ȡֵ�ػ�)
	ON_PREPARE    = 5,  -- �����������(��Ҫÿ֡�����ػ�)
	ON_CHANNEL    = 6,  -- �����������(��Ҫÿ֡�����ػ�)
	BREAK = 7,          -- ��϶���(�������)
	SUCCEED = 8,        -- �����ɹ�����(����)
	FAILED = 9,         -- ����ʧ�ܽ���(����)
	IDLE  = 10,         -- û�ж���(����)
}
local LB = class()
local HP = MY_LifeBar_HP
local CACHE = setmetatable({}, { __mode = "v" })

-- ���캯��
function LB:ctor(dwType, dwID)
	self.type = dwType
	self.id = dwID
	self.object = MY.GetObject(dwType, dwID)
	self.name = ""
	self.title = ""
	self.tong = ""
	self.life = -1
	self.force = -1
	self.relation = "Neutrality"
	self.info = {
		OT = {
			nState      = OT_STATE.IDLE,
			nPercentage = 0            ,
			szTitle     = ""           ,
			nStartFrame = 0            ,
			nFrameCount = 0            ,
		},
		nIndex = 0,
	}
	self.hp = HP(dwType, dwID)
	return self
end

-- ����UI
function LB:Create()
	if not self.hp.handle then
		self.hp:Create()
		self:Init()
	end
	return self
end

-- ɾ��UI
function LB:Remove()
	self.hp:Remove()
	return self
end

-- ��ʼ�� ������Զ�����ػ�Ķ���
function LB:Init()
	-- Ѫ���߿�
	local cfgLife = GetConfigValue("ShowLife", self.relation, self.force)
	if cfgLife then
		self.hp:DrawLifeBorder(Config.nLifeWidth, Config.nLifeHeight, Config.nLifeOffsetX, Config.nLifeOffsetY, Config.nAlpha)
	else
		self.hp:ClearLifeBorder()
	end
	return self
end

-- ���³�ʼ��
function LB:Reinit(bCreate)
	if bCreate and not self.hp.handle then
		self:Create()
	elseif self.hp.handle then
		self:Init()
		self:DrawLife()
		self:DrawNames()
		self:DrawOTTitle()
	end
	return self
end

-- ��Ŀ��ͷ����ɫ�����˾���������/������
function LB:FxColor(r,g,b,a)
	-- �����ж�
	if self.object.nMoveState == MOVE_STATE.ON_DEATH then
		if TARGET_ID == self.object.dwID then
			return math.ceil(r/2.2), math.ceil(g/2.2), math.ceil(b/2.2), a
		else
			return math.ceil(r/2.5), math.ceil(g/2.5), math.ceil(b/2.5), a
		end
	elseif TARGET_ID == self.object.dwID then
		return 255-(255-r)*0.3, 255-(255-g)*0.3, 255-(255-b)*0.3, a
	else
		return r,g,b,a
	end
end

-- ��������
function LB:SetName(name)
	if self.name ~= name then
		self.name = name
		self:DrawNames()
	end
	return self
end

-- ���óƺ�
function LB:SetTitle(title)
	if self.title ~= title then
		self.title = title
		self:DrawNames()
	end
	return self
end

-- ���ð��
function LB:SetTong(tong)
	if self.tong ~= tong then
		self.tong = tong
		self:DrawNames()
	end
	return self
end

-- �ػ�ͷ������
function LB:DrawNames()
	local tWordlines = {}
	local r,g,b,a,f
	local cfgName, cfgTitle, cfgTong
	if IsPlayer(self.object.dwID) then
		cfgLife  = GetConfigValue("ShowLife", self.relation, self.force)
		cfgName  = GetConfigValue("ShowName", self.relation, self.force)
		cfgTitle = GetConfigValue("ShowTitle", self.relation, self.force)
		cfgTong  = GetConfigValue("ShowTong", self.relation, self.force)
		r,g,b    = unpack(GetConfigValue("Color", self.relation, self.force))
	else
		cfgLife  = GetConfigValue("ShowLife", self.relation, self.force)
		cfgName  = GetConfigValue("ShowName", self.relation, self.force)
		cfgTitle = GetConfigValue("ShowTitle", self.relation, self.force)
		cfgTong  = false
		r,g,b    = unpack(GetConfigValue("Color", self.relation, self.force))
	end
	a,f = Config.nAlpha, Config.nFont
	r,g,b,a = self:FxColor(r,g,b,a)

	local i = #Config.nLineHeight
	if cfgTong then
		local szTong = self.tong
		if szTong and szTong ~= '' then
			table.insert(tWordlines, { szTong, Config.nLineHeight[i] })
			i = i - 1
		end
	end
	if cfgTitle then
		local szTitle = self.title
		if szTitle and szTitle ~= "" then
			table.insert(tWordlines, { "<" .. self.title .. ">", Config.nLineHeight[i] })
			i = i - 1
		end
	end
	if cfgName then
		local szName = self.name
		if szName and not tonumber(szName) then
			table.insert(tWordlines, { szName, Config.nLineHeight[i] })
			i = i - 1
		end
	end

	-- û�����ֵ���������Ѫ��
	if cfgName and #tWordlines == 0 then
		self.hp:DrawLifeBar(Config.nLifeWidth, Config.nLifeHeight, Config.nLifeOffsetX, Config.nLifeOffsetY, { r, g, b, 0, self.life, Config.szLifeDirection })
		self.hp:DrawLifeBorder(Config.nLifeWidth, Config.nLifeHeight, Config.nLifeOffsetX, Config.nLifeOffsetY, 0)
	elseif cfgLife then
		self.hp:DrawLifeBar(Config.nLifeWidth, Config.nLifeHeight, Config.nLifeOffsetX, Config.nLifeOffsetY, { r, g, b, a, self.life, Config.szLifeDirection })
		self.hp:DrawLifeBorder(Config.nLifeWidth, Config.nLifeHeight, Config.nLifeOffsetX, Config.nLifeOffsetY, a)
	end
	self.hp:DrawWordlines(tWordlines, {r,g,b,a,f})
	return self
end

-- ����Ѫ��
function LB:SetLife(life)
	if life < 0 or life > 1 then
		life = 1
	end -- fix
	if self.life ~= life then
		local dwLife = self.life
		self.life = life
		if dwLife < 0.01 or life < 0.01 then
			self:DrawNames()
		end
		self:DrawLife()
	end
	return self
end

function LB:DrawLife()
	local cfgLife    = GetConfigValue("ShowLife", self.relation, self.force)
	local cfgLifePer = GetConfigValue("ShowLifePer", self.relation, self.force)
	local r, g, b    = unpack(GetConfigValue("Color", self.relation, self.force))
	local a, f = Config.nAlpha, Config.nFont
	r, g, b, a = self:FxColor(r, g, b, a)
	if cfgLife then
		self.hp:DrawLifeBar(Config.nLifeWidth, Config.nLifeHeight, Config.nLifeOffsetX, Config.nLifeOffsetY, { r, g, b, a, self.life, Config.szLifeDirection })
	end
	if cfgLifePer then
		local szFormatString = '%.1f'
		if Config.bHideLifePercentageWhenFight and not GetClientPlayer().bFightState then
			szFormatString = ''
		elseif Config.bHideLifePercentageDecimal then
			szFormatString = '%.0f'
		end
		self.hp:DrawLifePercentage({string.format(szFormatString, 100 * self.life), Config.nLifePerOffsetX, Config.nLifePerOffsetY}, {r,g,b,a,f})
	end
	return self
end

function LB:SetForce(force)
	if self.force ~= force then
		self.force = force
		self:Reinit()
	end
	return self
end

function LB:SetRelation(relation)
	if self.relation ~= relation then
		self.relation = relation
		self:Reinit()
	end
	return self
end

-- ����/��ȡOT״̬
function LB:SetOTState(nState)
	if nState == OT_STATE.BREAK then
		self.info.OT.nStartFrame = GetLogicFrameCount()
		self:DrawOTBar({255,0,0}):DrawOTTitle({255,0,0})
	elseif nState == OT_STATE.SUCCEED then
		self.info.OT.nStartFrame = GetLogicFrameCount()
	end
	self.info.OT.nState = nState
	return self
end

function LB:GetOTState()
	return self.info.OT.nState
end

-- ���ö�������
function LB:SetOTTitle(szOTTitle, rgba)
	if self.info.OT.szTitle ~= szOTTitle then
		self.info.OT.szTitle = szOTTitle
		self:DrawOTTitle(rgba)
	end
	return self
end

function LB:DrawOTTitle(rgba)
	local cfgOTBar = GetConfigValue("ShowOTBar", self.relation, self.force)
	local r, g, b  = unpack(GetConfigValue("Color", self.relation, self.force))
	local a, f = Config.nAlpha, Config.nFont
	if rgba then r,g,b,a = rgba[1] or r, rgba[2] or g, rgba[3] or b, rgba[4] or a end
	r,g,b,a = self:FxColor(r,g,b,a)
	if cfgOTBar then
		self.hp:DrawOTTitle({ self.info.OT.szTitle, Config.nOTTitleOffsetX, Config.nOTTitleOffsetY }, {r,g,b,a,f})
	end
	return self
end

-- ���ö�������
function LB:SetOTPercentage(nPercentage, rgba)
	if nPercentage > 1 then nPercentage = 1 elseif nPercentage < 0 then nPercentage = 0 end
	if self.info.OT.nPercentage ~= nPercentage then
		self.info.OT.nPercentage = nPercentage
		self:DrawOTBar(rgba)
	end
	return self
end

function LB:DrawOTBar(rgba)
	local cfgOTBar = GetConfigValue("ShowOTBar", self.relation, self.force)
	local r, g, b  = unpack(GetConfigValue("Color", self.relation, self.force))
	local a, f = Config.nAlpha, Config.nFont
	if rgba then r,g,b,a,p = rgba[1] or r, rgba[2] or g, rgba[3] or b, rgba[4] or a end
	r,g,b,a = self:FxColor(r,g,b,a)
	if cfgOTBar then
		self.hp:DrawOTBar(Config.nOTBarWidth, Config.nOTBarHeight, Config.nOTBarOffsetX, Config.nOTBarOffsetY, { r, g, b, a, self.info.OT.nPercentage, Config.szOTBarDirection })
	end
	return self
end

function LB:DrawOTBarBorder(nAlpha)
	local cfgOTBar = GetConfigValue("ShowOTBar", self.relation, self.force)
	if cfgOTBar then
		self.hp:DrawOTBarBorder(Config.nOTBarWidth, Config.nOTBarHeight, Config.nOTBarOffsetX, Config.nOTBarOffsetY, nAlpha or Config.nAlpha)
	end
	return self
end

-- ��ʼ����
function LB:StartOTBar(szOTTitle, nFrameCount, bIsChannelSkill)
	self.info.OT = {
		nState = ( bIsChannelSkill and OT_STATE.START_CHANNEL ) or OT_STATE.START_PREPARE,
		szTitle = szOTTitle,
		nStartFrame = GetLogicFrameCount(),
		nFrameCount = nFrameCount,
	}
	return self
end

MY_LifeBar_LB = setmetatable({}, {
	__index = {
		OT_STATE = OT_STATE,
	},
	__call = function(t, dwType, dwID)
		if dwType == "clear" then
			CACHE = {}
			HP("clear")
		else
			local szName = dwType .. "_" .. dwID
			if not CACHE[szName] then
				CACHE[szName] = LB.new(dwType, dwID)
			end
			return CACHE[szName]
		end
	end,
})
