local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."XLifeBar/lang/")
local _SUB_ADDON_FOLDER_NAME_ = "XLifeBar"

-- ���ֻ��Ĭ������ ������û�õ� ���޸ĵĻ� �޸�data�ļ�
local Config = {
	Col = {
		Player = {
			Self = {30,140,220}, -- �Լ�
			Party = {30,140,220},-- �Ŷ�
			Enemy = {255,30,30},-- �ж�
			Neutrality = {255,255,0},-- ����
			Ally = {30,255,30},-- ��ͬ��Ӫ
		},
		Npc = {
			Party = {30,140,220},-- �Ŷ�
			Enemy = {255,30,30},-- �ж�
			Neutrality = {255,255,0},-- ����
			Ally = {30,255,30},-- ��ͬ��Ӫ
		}
	},
	SelectTarget = {255,220,220}, -- ��ǰĿ�������ɫ
	bShowName = {
		Player = {
			Self = true,
			Party = true,
			Neutrality = true,
			Enemy = true,
			Ally = true,
		},
		Npc = {
			Party = true,
			Neutrality = true,
			Enemy = true,
			Ally = true,
		},
	},
	bShowTong = {
		Player = {
			Self = true,
			Party = true,
			Neutrality = true,
			Enemy = true,
			Ally = true,
		},
		Npc = {
			Party = true,
			Neutrality = true,
			Enemy = true,
			Ally = true,
		},
	},
	bShowLife = {
		Player = {
			Self = true,
			Party = true,
			Neutrality = true,
			Enemy = true,
			Ally = true,
		},
		Npc = {
			Party = false,
			Neutrality = true,
			Enemy = true,
			Ally = true,
		},
	},
	bShowPer = {
		Player = {
			Self = false,
			Party = false,
			Neutrality = false,
			Enemy = false,
			Ally = false,
		},
		Npc = {
			Party = false,
			Neutrality = false,
			Enemy = false,
			Ally = false,
		},
	},
	bShowSpecialNpc = false,
	nWidth = 100,
	nHeight = 8,
	nFont = 23,
	nFirstHeight = 50,
	nSecondHeight = 30,
	nPerHeight = 11,
	nLifeHeight = 0,
	nDistance = 24,
}


XLifeBar = {}
XLifeBar.bEnabled = false
RegisterCustomData("XLifeBar.bEnabled")
local _XLifeBar = {
	dwVersion = 0x0000700,
	szConfig = "userdata/XLifeBar/CFG",
	tObject = {},
	tTongList = {},
	tNpc = {},
	tPlayer = {},
	dwTargetID = 0,
	Lang = {
		Neutrality = "������ϵ",
		Enemy = "�жԹ�ϵ",
		Ally = "�Ѻù�ϵ",
		Party = "���ѹ�ϵ",
		Self = "�Լ�",
	}
}
-- SaveLUAData(_XLifeBar.szConfig,Config) -- ����
MY.RegisterInit(function()
	Config = MY.Sys.LoadUserData(_XLifeBar.szConfig) or Config
	_XLifeBar.Reset(true)
end)


_XLifeBar.GetMenu = function()
	local menu = {
		szOption = "��ƽѪ��",
		bCheck = true,
		bChecked = XLifeBar.bEnabled,
		fnAction = function()
			XLifeBar.bEnabled = not XLifeBar.bEnabled
			if not XLifeBar.bEnabled then
				_XLifeBar.Reset(true)
			end
		end,
	}
	table.insert(menu,{	szOption = "����/�ر�",
		{
			szOption = "����",
			bCheck = true,
			bMCheck = true,
			bChecked = XLifeBar.bEnabled,
			fnAction = function()
				XLifeBar.bEnabled = true
				if not XLifeBar.bEnabled then
					_XLifeBar.Reset(true)
				end
			end,
		}, {
			szOption = "�ر�",
			bCheck = true,
			bMCheck = true,
			bChecked = not XLifeBar.bEnabled,
			fnAction = function()
				XLifeBar.bEnabled = false
				if not XLifeBar.bEnabled then
					_XLifeBar.Reset(true)
				end
			end,
		}
	})
	table.insert(menu,{	bDevide = true} )
	-- ��ʾ����
	table.insert(menu,{	szOption = "������ʾ����"})
	table.insert(menu[3],{	szOption = "���������ʾ" , bDisable = true} )
	for k,v in pairs(Config.bShowName.Player) do
		table.insert(menu[3],{
			szOption = _XLifeBar.Lang[k], 
			bCheck = true, 
			bChecked = Config.bShowName.Player[k],
			fnAction = function() 
				Config.bShowName.Player[k] = not Config.bShowName.Player[k]
				_XLifeBar.Reset()
			end,
			rgb = Config.Col.Player[k],
			bColorTable = true,
			fnChangeColor = function(_,r,g,b)
				Config.Col.Player[k] = {r,g,b}
				_XLifeBar.Reset()
			end
		})
	end
	table.insert(menu[3],{	bDevide = true} )
	table.insert(menu[3],{	szOption = "Npc������ʾ" , bDisable = true} )
	for k,v in pairs(Config.bShowName.Npc) do
		table.insert(menu[3],{
			szOption = _XLifeBar.Lang[k], 
			bCheck = true, 
			bChecked = Config.bShowName.Npc[k],
			fnAction = function() 
				Config.bShowName.Npc[k] = not Config.bShowName.Npc[k]
				_XLifeBar.Reset() 
			end,
			rgb = Config.Col.Npc[k],
			bColorTable = true,
			fnChangeColor = function(_,r,g,b)
				Config.Col.Npc[k] = {r,g,b}
				_XLifeBar.Reset()
			end
		})
	end
	
	-- ���
	table.insert(menu,{	szOption = "����ƺ���ʾ����"})
	table.insert(menu[4],{	szOption = "��Ұ����ʾ" , bDisable = true} )
	for k,v in pairs(Config.bShowTong.Player) do
		table.insert(menu[4],{
			szOption = _XLifeBar.Lang[k], 
			bCheck = true, 
			bChecked = Config.bShowTong.Player[k],
			fnAction = function() 
				Config.bShowTong.Player[k] = not Config.bShowTong.Player[k];
				_XLifeBar.Reset() 
			end,
			rgb = Config.Col.Player[k],
			bColorTable = true,
			fnChangeColor = function(_,r,g,b)
				Config.Col.Player[k] = {r,g,b}
				_XLifeBar.Reset()
			end
		})
	end
	table.insert(menu[4],{	bDevide = true} )
	table.insert(menu[4],{	szOption = "Npc�ƺ���ʾ" , bDisable = true} )
	for k,v in pairs(Config.bShowTong.Npc) do
		table.insert(menu[4],{
			szOption = _XLifeBar.Lang[k], 
			bCheck = true, 
			bChecked = Config.bShowTong.Npc[k],
			fnAction = function() 
				Config.bShowTong.Npc[k] = not Config.bShowTong.Npc[k]
				_XLifeBar.Reset() 
			end,
			rgb = Config.Col.Npc[k],
			bColorTable = true,
			fnChangeColor = function(_,r,g,b)
				Config.Col.Npc[k] = {r,g,b}
				_XLifeBar.Reset()
			end
		})
	end
	
	-- Ѫ������
	table.insert(menu,{	szOption = "Ѫ����ʾ����"})
	table.insert(menu[5],{	szOption = "���Ѫ����ʾ" , bDisable = true} )
	for k,v in pairs(Config.bShowLife.Player) do
		table.insert(menu[5],{
			szOption = _XLifeBar.Lang[k], 
			bCheck = true, 
			bChecked = Config.bShowLife.Player[k],
			fnAction = function() 
				Config.bShowLife.Player[k] = not Config.bShowLife.Player[k]
				_XLifeBar.Reset() 
			end,
			rgb = Config.Col.Player[k],
			bColorTable = true,
			fnChangeColor = function(_,r,g,b)
				Config.Col.Player[k] = {r,g,b}
				_XLifeBar.Reset()
			end
		})
	end
	table.insert(menu[5],{	bDevide = true} )
	table.insert(menu[5],{	szOption = "NpcѪ����ʾ" , bDisable = true} )
	for k,v in pairs(Config.bShowLife.Npc) do
		table.insert(menu[5],{
			szOption = _XLifeBar.Lang[k], 
			bCheck = true, 
			bChecked = Config.bShowLife.Npc[k],
			fnAction = function() 
				Config.bShowLife.Npc[k] = not Config.bShowLife.Npc[k]
				_XLifeBar.Reset() 
			end,
			rgb = Config.Col.Npc[k],
			bColorTable = true,
			fnChangeColor = function(_,r,g,b)
				Config.Col.Npc[k] = {r,g,b}
				_XLifeBar.Reset()
			end
		})
	end
	
	-- ��ʾѪ��%
	table.insert(menu,{	szOption = "Ѫ���ٷֱ���ʾ����"})
	table.insert(menu[6],{	szOption = "��Ұٷֱ���ʾ" , bDisable = true} )
	for k,v in pairs(Config.bShowPer.Player) do
		table.insert(menu[6],{
			szOption = _XLifeBar.Lang[k], 
			bCheck = true, 
			bChecked = Config.bShowPer.Player[k],
			fnAction = function() 
				Config.bShowPer.Player[k] = not Config.bShowPer.Player[k]
				_XLifeBar.Reset() 
			end,
			rgb = Config.Col.Player[k],
			bColorTable = true,
			fnChangeColor = function(_,r,g,b)
				Config.Col.Player[k] = {r,g,b}
				_XLifeBar.Reset()
			end
		})
	end
	table.insert(menu[6],{	bDevide = true} )
	table.insert(menu[6],{	szOption = "Npc�ٷֱ���ʾ" , bDisable = true} )
	for k,v in pairs(Config.bShowPer.Npc) do
		table.insert(menu[6],{
			szOption = _XLifeBar.Lang[k], 
			bCheck = true, 
			bChecked = Config.bShowPer.Npc[k],
			fnAction = function() 
				Config.bShowPer.Npc[k] = not Config.bShowPer.Npc[k];
				_XLifeBar.Reset() 
			end,
			rgb = Config.Col.Npc[k],
			bColorTable = true,
			fnChangeColor = function(_,r,g,b)
				Config.Col.Npc[k] = {r,g,b}
				_XLifeBar.Reset()
			end
		})
	end
	
	table.insert(menu,{	bDevide = true} )
	table.insert(menu,{	szOption = "��ʾ����Npc", bCheck = true, bChecked = Config.bShowSpecialNpc,fnAction = function() Config.bShowSpecialNpc = not Config.bShowSpecialNpc;_XLifeBar.Reset() end})
	table.insert(menu,{	szOption = "�����ʾ���� " .. Config.nDistance, fnAction = function() 
		local fX, fY = Cursor.GetPos()
		GetUserPercentage(function(f)
			Config.nDistance = math.ceil(300 * f)
			_XLifeBar.Reset()
		end,nil,Config.nDistance / 300,"�����ʾ����",{ fX, fY, fX + 1, fY + 1 } )
	end})
	
	
	table.insert(menu,{	bDevide = true} )
	table.insert(menu,{
		szOption = "��ǰĿ�������ɫ", 
		rgb = Config.SelectTarget,
		bColorTable = true,
		fnChangeColor = function(_,r,g,b)
			Config.SelectTarget = {r,g,b}
			_XLifeBar.Reset()
		end
	})
	table.insert(menu,{	bDevide = true} )
	
	table.insert(menu,{	szOption = "����Ѫ������ " .. Config.nWidth, fnAction = function() 
		local fX, fY = Cursor.GetPos()
		GetUserPercentage(function(f)
			Config.nWidth = math.ceil(150 * f)
			_XLifeBar.Reset()
		end,nil,Config.nWidth / 150,"Ѫ������",{ fX, fY, fX + 1, fY + 1 } )
	end})
	table.insert(menu,{	szOption = "����Ѫ����� " .. Config.nHeight, fnAction = function() 
		local fX, fY = Cursor.GetPos()
		GetUserPercentage(function(f)
			Config.nHeight = math.ceil(15 * f)
			_XLifeBar.Reset()
		end,nil,Config.nHeight / 15,"Ѫ�����",{ fX, fY, fX + 1, fY + 1 } )
	end})
	table.insert(menu,{	szOption = "������ʽ " .. Config.nFont, fnAction = function() 
		GetUserInput("����������ʽ",function(text)
			if tonumber(text) then
				Config.nFont = tonumber(text)
				_XLifeBar.Reset()
			end
		end,nil,nil,nil,Config.nFont)
	end})
	table.insert(menu,{	bDevide = true} )
	table.insert(menu,{	szOption = "��һ���ָ߶� " .. Config.nFirstHeight, fnAction = function() 
		local fX, fY = Cursor.GetPos()
		GetUserPercentage(function(f)
			Config.nFirstHeight = math.ceil(150 * f)
			_XLifeBar.Reset()
		end,nil,Config.nFirstHeight / 150,"��һ���ָ߶�",{ fX, fY, fX + 1, fY + 1 } )
	end})
	table.insert(menu,{	szOption = "�ڶ����ָ߶� " .. Config.nSecondHeight, fnAction = function() 
		local fX, fY = Cursor.GetPos()
		GetUserPercentage(function(f)
			Config.nSecondHeight = math.ceil(150 * f)
			_XLifeBar.Reset()
		end,nil,Config.nSecondHeight / 150,"�ڶ����ָ߶�",{ fX, fY, fX + 1, fY + 1 } )
	end})
	table.insert(menu,{	szOption = "�ٷֱȸ߶� " .. Config.nPerHeight, fnAction = function() 
		local fX, fY = Cursor.GetPos()
		GetUserPercentage(function(f)
			Config.nPerHeight = math.ceil(150 * f)
			_XLifeBar.Reset()
		end,nil,Config.nPerHeight / 150,"�ٷֱȸ߶�",{ fX, fY, fX + 1, fY + 1 } )
	end})
	
	table.insert(menu,{	szOption = "Ѫ���߶� " .. Config.nLifeHeight, fnAction = function() 
		local fX, fY = Cursor.GetPos()
		GetUserPercentage(function(f)
			Config.nLifeHeight = math.ceil(50 * f)
			_XLifeBar.Reset()
		end,nil,Config.nLifeHeight / 50,"Ѫ���߶�",{ fX, fY, fX + 1, fY + 1 } )
	end})
	
	
	return menu
end

_XLifeBar.GetName = function(tar)
	local szName = tar.szName
	if szName == "" and not IsPlayer(tar.dwID) then
		szName = string.gsub(Table_GetNpcTemplateName(tar.dwTemplateID), "^%s*(.-)%s*$", "%1")
		if szName == "" then
			szName = tar.dwID
		end
	end
	if tar.dwEmployer and tar.dwEmployer ~= 0 and szName == Table_GetNpcTemplateName(tar.dwTemplateID) then
		local emp = GetPlayer(tar.dwEmployer)
		if not emp then
			szName =  g_tStrings.STR_SOME_BODY .. g_tStrings.STR_PET_SKILL_LOG .. tar.szName
		else
			szName = emp.szName .. g_tStrings.STR_PET_SKILL_LOG .. tar.szName
		end
	end
	return szName
end


_XLifeBar.GetObject = function(dwID)
	local Object
	if IsPlayer(dwID) then
		Object = GetPlayer(dwID)
	else
		Object = GetNpc(dwID)
	end
	return Object
end
_XLifeBar.GetNz = function(nZ,nZ2)
	return math.floor(((nZ/8 - nZ2/8) ^ 2) ^ 0.5)/64
end

_XLifeBar.GetForce = function(dwID)
	local me = GetClientPlayer()
	if not me then
		return "Neutrality"
	end
	if dwID == me.dwID then
		return "Self"
	end
	if IsParty(me.dwID, dwID) then
		return "Party"
	end
	if IsNeutrality(me.dwID,dwID) then
		return "Neutrality"
	end
	if IsEnemy(me.dwID,dwID) then -- �жԹ�ϵ
		local r,g,b = GetHeadTextForceFontColor(dwID,me.dwID)
		if r == 255 and g == 255 and b == 0 then
			return "Neutrality"
		else
			return "Enemy"
		end
	end
	if IsAlly(me.dwID, dwID) then -- ��ͬ��Ӫ
		return "Ally"
	end
	
	return "Neutrality" -- "Other"
end

_XLifeBar.Reset = function(bNoSave)
	_XLifeBar.tObject = {}
	_XLifeBar.Frame:Lookup("",""):Clear()
	if not bNoSave then
		MY.Sys.SaveUserData(_XLifeBar.szConfig, Config)
	end
end

local HP = class()

function HP:ctor(object) -- KGobject
	self.self = object
	self.dwID = object.dwID
	self.force = _XLifeBar.GetForce(object.dwID)
	return self
end
-- ����
function HP:Create()
	-- Create handle
	local frame = _XLifeBar.Frame
	if not frame:Lookup("",tostring(self.dwID)) then
		local Total = frame:Lookup("","")
		Total:AppendItemFromString(FormatHandle( string.format("name=\"%s\"",self.dwID) ))
	end
	local handle = frame:Lookup("",tostring(self.dwID))
	local lifeper = self.self.nCurrentLife / self.self.nMaxLife
	if lifeper > 1 or lifeper < 0 then lifeper = 1 end -- fix
	
	_XLifeBar.tObject[self.dwID] = {
		Lifeper = lifeper,
		handle = handle,
		Force = self.force,
	}
	if not handle:Lookup(string.format("bg_%s",self.dwID)) then
		handle:AppendItemFromString( string.format("<shadow>name=\"bg_%s\"</shadow>",self.dwID) )
		handle:AppendItemFromString( string.format("<shadow>name=\"bg2_%s\"</shadow>",self.dwID) )
		handle:AppendItemFromString( string.format("<shadow>name=\"hp_%s\"</shadow>",self.dwID) )
		handle:AppendItemFromString( string.format("<shadow>name=\"name_%s\"</shadow>",self.dwID) )
		self:DrawBorder(150)
		self:DrawName()
	end
	--����Ѫ��
	self:DrawLife(lifeper)
	return self
end


-- ɾ��
function HP:Remove()
	local frame = _XLifeBar.Frame
	if frame:Lookup("",tostring(self.dwID)) then
		local Total = frame:Lookup("","")
		Total:RemoveItem(frame:Lookup("",tostring(self.dwID)))		
	end
	_XLifeBar.tObject[self.dwID] = nil
	return self
end

-- ���߿� Ĭ��200��nAlpha
function HP:DrawBorder(nAlpha)
	local tab = _XLifeBar.tObject[self.dwID]
	local handle = tab.handle
	
	local cfgLife = Config.bShowLife.Npc[self.force]
	if IsPlayer(self.dwID) then
		cfgLife = Config.bShowLife.Player[self.force]
	end
	
	
	if cfgLife then
		-- ������߿�
		local sha = handle:Lookup(string.format("bg_%s",self.dwID))
		sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		sha:SetD3DPT(D3DPT.TRIANGLEFAN)
		sha:ClearTriangleFanPoint()
		local bcX,bcY = - Config.nWidth / 2 ,(- Config.nHeight) - Config.nLifeHeight

		sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX,bcY})
		sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX+Config.nWidth,bcY})
		sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX+Config.nWidth,bcY+Config.nHeight})
		sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX,bcY+Config.nHeight})

		-- �����ڱ߿�
		local sha = handle:Lookup(string.format("bg2_%s",self.dwID))
		sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		sha:SetD3DPT(D3DPT.TRIANGLEFAN)
		sha:ClearTriangleFanPoint()		
		local bcX,bcY = - (Config.nWidth / 2 - 1),(- (Config.nHeight - 1)) - Config.nLifeHeight

		sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX,bcY})
		sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX+(Config.nWidth - 2),bcY})
		sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX+(Config.nWidth - 2),bcY+(Config.nHeight - 2)})
		sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX,bcY+(Config.nHeight - 2)})		
	end
	return self
end

function HP:DrawName(col)
	local tab = _XLifeBar.tObject[self.dwID]
	local handle = tab.handle
	local sha = handle:Lookup(string.format("name_%s",self.dwID))

	
	local cfgTong = Config.bShowTong.Player[self.force]
	local cfgName = Config.bShowName.Player[self.force]
	local cfgPer = Config.bShowPer.Player[self.force]
	local r,g,b = unpack(Config.Col.Player[self.force])
	
	if not IsPlayer(self.dwID) then
		cfgTong = Config.bShowTong.Npc[self.force]
		cfgName = Config.bShowName.Npc[self.force]
		cfgPer = Config.bShowPer.Npc[self.force]
		r,g,b = unpack(Config.Col.Npc[self.force])
	end
	
	if type(col) == "table" then
		r,g,b = unpack(col)
	elseif type(col) == "number" then
		r,g,b = math.ceil(r/col),math.ceil(g/col),math.ceil(b/col)
	end
	
	sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
	sha:ClearTriangleFanPoint()
	if cfgTong and cfgName then
		local szTitle
		if not IsPlayer(self.dwID) and self.self.szTitle ~= "" then -- Npc ��ʾ�ƺ�
			szTitle = "<" .. self.self.szTitle .. ">"
		elseif IsPlayer(self.dwID) and self.self.dwTongID ~= 0 then -- ��� ��ʾ���
			if not _XLifeBar.tTongList[self.self.dwTongID] then
				if GetTongClient().ApplyGetTongName(self.self.dwTongID) then
					_XLifeBar.tTongList[self.self.dwTongID] = GetTongClient().ApplyGetTongName(self.self.dwTongID)
				end
			end
			if _XLifeBar.tTongList[self.self.dwTongID] then
				szTitle = "[" .. _XLifeBar.tTongList[self.self.dwTongID] .. "]"
			end
		end
		if szTitle then
			sha:AppendCharacterID(self.dwID,true,r,g,b,255,{0,0,0,0,- Config.nFirstHeight},Config.nFont,_XLifeBar.GetName(self.self),1,1)
			sha:AppendCharacterID(self.dwID,true,r,g,b,255,{0,0,0,0,- Config.nSecondHeight},Config.nFont,szTitle,1,1)
		else
			sha:AppendCharacterID(self.dwID,true,r,g,b,255,{0,0,0,0,- Config.nSecondHeight},Config.nFont,_XLifeBar.GetName(self.self),1,1)
		end
	elseif cfgName then
		sha:AppendCharacterID(self.dwID,true,r,g,b,255,{0,0,0,0,- Config.nSecondHeight},Config.nFont,_XLifeBar.GetName(self.self),1,1)
	end
	
	if cfgPer then
		sha:AppendCharacterID(self.dwID,true,r,g,b,220,{0,0,0,0,- Config.nPerHeight},Config.nFont,string.format("%.1f", 100 * tab.Lifeper),1,1)
	end
end

-- ���Ѫ��
function HP:DrawLife(Lifeper,col)
	local tab = _XLifeBar.tObject[self.dwID]
	local handle = tab.handle
	
	local r,g,b = unpack(Config.Col.Player[self.force])
	local cfgLife = Config.bShowLife.Player[self.force]
	if not IsPlayer(self.dwID) then
		cfgLife = Config.bShowLife.Npc[self.force]
		r,g,b = unpack(Config.Col.Npc[self.force])
	end
	if col then
		r,g,b = unpack(col)
	end

	if cfgLife then
		--����Ѫ��
		local sha = handle:Lookup(string.format("hp_%s",self.dwID))

		sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		sha:SetD3DPT(D3DPT.TRIANGLEFAN)
		sha:ClearTriangleFanPoint()

		local bcX,bcY = - (Config.nWidth / 2 - 2),(- (Config.nHeight - 2)) - Config.nLifeHeight
		local Lifeper = Lifeper or tab.Lifeper
		local Life = (Config.nWidth - 4) * Lifeper

		
		sha:AppendCharacterID(self.dwID,true,r,g,b,200,{0,0,0,bcX,bcY})
		sha:AppendCharacterID(self.dwID,true,r,g,b,200,{0,0,0,bcX+Life,bcY})
		sha:AppendCharacterID(self.dwID,true,r,g,b,200,{0,0,0,bcX+Life,bcY+(Config.nHeight - 4)})
		sha:AppendCharacterID(self.dwID,true,r,g,b,200,{0,0,0,bcX,bcY+(Config.nHeight - 4)})
	end
	return self
end


XLifeBar.Create = function(...)
	local self = HP.new(...)
	return self
end
setmetatable(XLifeBar, { __call = function(me, ...) return me.Create(...) end, __metatable = true })

function XLifeBar.OnFrameCreate()
	_XLifeBar.Frame = this
end

function XLifeBar.OnFrameBreathe()
	if not XLifeBar.bEnabled then return end
	local me = GetClientPlayer()
	if not me then return end
	-- local _, _, fPitch = Camera_GetRTParams()
	for k , v in pairs(_XLifeBar.tNpc) do
		local object = GetNpc(k)
		if GetCharacterDistance(me.dwID,k) / 64 < Config.nDistance --[[ ���Ǿ�ͷ�����ж� ���ǲ������Ȳ��� and (fPitch > -0.8 or _XLifeBar.GetNz(me.nZ,object.nZ) < Config.nDistance / 2.5)]] then
			if not _XLifeBar.tObject[k] then
				if object.CanSeeName() or Config.bShowSpecialNpc then
					XLifeBar(object):Create()
				end
			else
				local tab = _XLifeBar.tObject[k]
				-- Ѫ���ж�
				local lifeper = object.nCurrentLife / object.nMaxLife
				if lifeper > 1 or lifeper < 0 then lifeper = 1 end -- fix
				if lifeper ~= tab.Lifeper then
					tab.Lifeper = lifeper
					XLifeBar(object):DrawLife(lifeper):DrawName() -- Ѫ���䶯��ʱ���ػ����� 
				end

				
				-- �����л�
				local Force = _XLifeBar.GetForce(k)
				if Force ~= tab.Force then
					XLifeBar(object):Remove():Create()
				end
				-- ��ǰĿ��
				if _XLifeBar.dwTargetID == object.dwID then
					XLifeBar(object):DrawLife(lifeper,Config.SelectTarget):DrawName(Config.SelectTarget) -- �ݶ� 
				end
				
					-- �����ж�
				if object.nMoveState == MOVE_STATE.ON_DEATH then
					if _XLifeBar.dwTargetID == object.dwID then
						XLifeBar(object):DrawLife(0):DrawName(2.2)
					else
						XLifeBar(object):DrawLife(0):DrawName(2.5)
					end
				end
			end
		elseif _XLifeBar.tObject[k] then
			XLifeBar(object):Remove()
		end
	end
	
	for k , v in pairs(_XLifeBar.tPlayer) do
		local object = GetPlayer(k)
		if object.szName ~= "" then
			if GetCharacterDistance(me.dwID,k) / 64 < Config.nDistance --[[ ���Ǿ�ͷ�����ж� ���ǲ������Ȳ��� and (fPitch > -0.8 or _XLifeBar.GetNz(me.nZ,object.nZ) < Config.nDistance / 2.5)]] then
				if not _XLifeBar.tObject[k] then
					XLifeBar(object):Create()
				else
					local tab = _XLifeBar.tObject[k]
					-- Ѫ���ж�
					local lifeper = object.nCurrentLife / object.nMaxLife
					if lifeper > 1 or lifeper < 0 then lifeper = 1 end -- fix
					if lifeper ~= tab.Lifeper then
						tab.Lifeper = lifeper
						XLifeBar(object):DrawLife(lifeper):DrawName() -- Ѫ���䶯��ʱ���ػ����� 
					end
					
					-- �����л�
					local Force = _XLifeBar.GetForce(k)
					if Force ~= tab.Force then
						XLifeBar(object):Remove():Create()
					end
					
					-- ��ǰĿ��
					if _XLifeBar.dwTargetID == object.dwID then
						XLifeBar(object):DrawLife(lifeper,Config.SelectTarget):DrawName(Config.SelectTarget) -- �ݶ� 
					end
					
					-- �����ж�
					if object.nMoveState == MOVE_STATE.ON_DEATH then
						if _XLifeBar.dwTargetID == object.dwID then
							XLifeBar(object):DrawLife(0):DrawName(2.2)
						else
							XLifeBar(object):DrawLife(0):DrawName(2.5)
						end
					end
					
				end
			elseif _XLifeBar.tObject[k] then
				XLifeBar(object):Remove()
			end
		end
	end
	
end

RegisterEvent("NPC_ENTER_SCENE",function()
	_XLifeBar.tNpc[arg0] = true
end)

RegisterEvent("NPC_LEAVE_SCENE",function()
	_XLifeBar.tNpc[arg0] = nil
	local object = GetNpc(arg0)
	XLifeBar(object):Remove()
end)

RegisterEvent("PLAYER_ENTER_SCENE",function()
	_XLifeBar.tPlayer[arg0] = true
end)

RegisterEvent("PLAYER_LEAVE_SCENE",function()
	_XLifeBar.tPlayer[arg0] = nil
	local object = GetPlayer(arg0)
	XLifeBar(object):Remove()
end)

RegisterEvent("UPDATE_SELECT_TARGET",function()
	local dwID,_ = Target_GetTargetData()
	if _XLifeBar.dwTargetID == dwID then
		return
	end
	if _XLifeBar.tObject[_XLifeBar.dwTargetID] then
		XLifeBar(_XLifeBar.GetObject(_XLifeBar.dwTargetID)):DrawLife():DrawName()
	end
	_XLifeBar.dwTargetID = dwID
end)

-- RegisterEvent("CALL_LUA_ERROR", function()
	-- Output(arg0)
-- end)
MY.RegisterPlayerAddonMenu( 'XLifeBar', _XLifeBar.GetMenu )
MY.RegisterTraceButtonMenu( 'XLifeBar', _XLifeBar.GetMenu )
-- RegisterEvent("FIRST_LOADING_END", function()
-- 	Player_AppendAddonMenu({function() return {_XLifeBar.GetMenu()} end})
-- 	-- Wnd.ToggleWindow("CombatTextWnd")
-- 	-- Wnd.ToggleWindow("CombatTextWnd")
	
-- end)
Wnd.OpenWindow("interface/MY/XLifeBar/XLifeBar.ini","XLifeBar")
