--------------------------------------------
-- @Desc  : ��ƽѪ��UI������
--          ֻ��UI���� �����κ��߼��ж�
-- @Author: ��һ�� @tinymins
-- @Date  : 2015-03-02 10:08:35
-- @Email : admin@derzh.com
-- @Last Modified by:   ��һ�� @tinymins
-- @Last Modified time: 2015-05-14 10:27:36
--------------------------------------------
local l_handle
XLifeBar = XLifeBar or {}
XLifeBar.HP = class()
local HP = XLifeBar.HP

function HP:ctor(dwID) -- KGobject
	if not l_handle then
		l_handle = XGUI.GetShadowHandle("XLifeBar")
	end
	self.dwID = dwID
	self.handle = l_handle:Lookup(tostring(self.dwID))
	return self
end
-- ����
function HP:Create()
	-- Create handle
	if not l_handle:Lookup(tostring(self.dwID)) then
		l_handle:AppendItemFromString(FormatHandle( string.format("name=\"%s\"",self.dwID) ))
	end

	local handle = l_handle:Lookup(tostring(self.dwID))
	if not handle:Lookup(string.format("hp_bg_%s",self.dwID)) then
		handle:AppendItemFromString( string.format("<shadow>name=\"hp_bg_%s\"</shadow>",self.dwID) )
		handle:AppendItemFromString( string.format("<shadow>name=\"hp_bg2_%s\"</shadow>",self.dwID) )
		handle:AppendItemFromString( string.format("<shadow>name=\"hp_%s\"</shadow>",self.dwID) )
		handle:AppendItemFromString( string.format("<shadow>name=\"ot_bg_%s\"</shadow>",self.dwID) )
		handle:AppendItemFromString( string.format("<shadow>name=\"ot_bg2_%s\"</shadow>",self.dwID) )
		handle:AppendItemFromString( string.format("<shadow>name=\"ot_%s\"</shadow>",self.dwID) )
		handle:AppendItemFromString( string.format("<shadow>name=\"lines_%s\"</shadow>",self.dwID) )
		handle:AppendItemFromString( string.format("<shadow>name=\"hp_title_%s\"</shadow>",self.dwID) )
		handle:AppendItemFromString( string.format("<shadow>name=\"ot_title_%s\"</shadow>",self.dwID) )
	end
	self.handle = handle
	return self
end

-- ɾ��
function HP:Remove()
	if l_handle:Lookup(tostring(self.dwID)) then
		l_handle:RemoveItem(l_handle:Lookup(tostring(self.dwID)))
	end
	return self
end

-- ��������/���/�ƺ� �ȵ� ������
-- rgbaf: ��,��,��,͸����,����
-- tWordlines: {[����,�߶�ƫ��],...}
function HP:DrawWordlines(tWordlines, rgbaf)
	if self.handle then
		local r,g,b,a,f = unpack(rgbaf)
		local sha = self.handle:Lookup(string.format("lines_%s",self.dwID))

		sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
		sha:ClearTriangleFanPoint()

		for _, aWordline in ipairs(tWordlines) do
			if aWordline[1] and #aWordline[1] > 0 then
				sha:AppendCharacterID(self.dwID,true,r,g,b,a,{0,0,0,0,- aWordline[2]},f,aWordline[1],1,1)
			end
		end
	end
	return self
end

-- ����Ѫ���ٷֱ����֣������ػ�������Ժ�Wordlines���룩
function HP:DrawLifePercentage(aWordline, rgbaf)
	if not self.handle then
		return
	end
	local r,g,b,a,f = unpack(rgbaf)
	local sha = self.handle:Lookup(string.format("hp_title_%s",self.dwID))

	sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
	sha:ClearTriangleFanPoint()

	if aWordline[1] and #aWordline[1] > 0 then
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, { 0, 0, 0, aWordline[2], - aWordline[3] }, f, aWordline[1], 1, 1)
	end
	return self
end

-- ���ƶ������ƣ������ػ�������Ժ�Wordlines���룩
function HP:DrawOTTitle(aWordline, rgbaf)
	if self.handle then
		local r,g,b,a,f = unpack(rgbaf)
		local sha = self.handle:Lookup(string.format("ot_title_%s",self.dwID))

		sha:SetTriangleFan(GEOMETRY_TYPE.TEXT)
		sha:ClearTriangleFanPoint()

		if aWordline[1] and #aWordline[1] > 0 then
			sha:AppendCharacterID(self.dwID, true, r, g, b, a, { 0, 0, 0, aWordline[2], - aWordline[3] }, f, aWordline[1], 1, 1)
		end
	end
	return self
end

-- ���߿� Ĭ��200��nAlpha
function HP:DrawBorder(nWidth, nHeight, nOffsetX, nOffsetY, nAlpha, szShadowName, szShadowName2)
	if self.handle then
		nAlpha = nAlpha or 200
		nWidth   = nWidth * Station.GetUIScale()
		nHeight  = nHeight * Station.GetUIScale()
		nOffsetX = nOffsetX * Station.GetUIScale()
		nOffsetY = nOffsetY * Station.GetUIScale()
		local handle = self.handle

		-- ������߿�
		local sha = handle:Lookup(string.format(szShadowName,self.dwID))
		sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		sha:SetD3DPT(D3DPT.TRIANGLEFAN)
		sha:ClearTriangleFanPoint()
		local bcX,bcY = - nWidth / 2 + nOffsetX, (- nHeight) - nOffsetY

		sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX,bcY})
		sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX+nWidth,bcY})
		sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX+nWidth,bcY+nHeight})
		sha:AppendCharacterID(self.dwID,true,180,180,180,nAlpha,{0,0,0,bcX,bcY+nHeight})

		-- �����ڱ߿�
		local sha = handle:Lookup(string.format(szShadowName2,self.dwID))
		sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		sha:SetD3DPT(D3DPT.TRIANGLEFAN)
		sha:ClearTriangleFanPoint()
		local bcX,bcY = - (nWidth / 2 - 1) + nOffsetX, (- (nHeight - 1)) - nOffsetY

		sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX,bcY})
		sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX+(nWidth - 2),bcY})
		sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX+(nWidth - 2),bcY+(nHeight - 2)})
		sha:AppendCharacterID(self.dwID,true,30,30,30,nAlpha,{0,0,0,bcX,bcY+(nHeight - 2)})
	end
	return self
end

-- ���Ѫ���߿� Ĭ��200��nAlpha
function HP:DrawLifeBorder(nWidth, nHeight, nOffsetX, nOffsetY, nAlpha)
	return self:DrawBorder(nWidth, nHeight, nOffsetX, nOffsetY, nAlpha, "hp_bg_%s", "hp_bg2_%s")
end
-- �������߿� Ĭ��200��nAlpha
function HP:DrawOTBarBorder(nWidth, nHeight, nOffsetX, nOffsetY, nAlpha)
	return self:DrawBorder(nWidth, nHeight, nOffsetX, nOffsetY, nAlpha, "ot_bg_%s", "ot_bg2_%s")
end

-- �����Σ�������/Ѫ����
-- rgbap: ��,��,��,͸����,����,���Ʒ���
function HP:DrawRect(nWidth, nHeight, nOffsetX, nOffsetY, rgbapd, szShadowName)
	if self.handle then
		local r,g,b,a,p,d = unpack(rgbapd)
		nWidth   = nWidth * Station.GetUIScale()
		nHeight  = nHeight * Station.GetUIScale()
		nOffsetX = nOffsetX * Station.GetUIScale()
		nOffsetY = nOffsetY * Station.GetUIScale()
		if not p or p > 1 then
			p = 1
		elseif p < 0 then
			p = 0
		end -- fix
		local sha = self.handle:Lookup(string.format(szShadowName,self.dwID))

		sha:SetTriangleFan(GEOMETRY_TYPE.TRIANGLE)
		sha:SetD3DPT(D3DPT.TRIANGLEFAN)
		sha:ClearTriangleFanPoint()

		-- ����ʵ�ʻ��ƿ�ȸ߶���ʼλ��
		local bcX, bcY = - (nWidth / 2 - 2) + nOffsetX, (- (nHeight - 2)) - nOffsetY
		if d == "TOP_BOTTOM" then
			nWidth = nWidth - 4
			nHeight = (nHeight - 4) * p
		elseif d == "BOTTOM_TOP" then
			bcY = bcY + (nHeight - 4) * (1 - p)
			nWidth = nWidth - 4
			nHeight = (nHeight - 4) * p
		elseif d == "RIGHT_LEFT" then
			bcX = bcX + (nWidth - 4) * (1 - p)
			nWidth = (nWidth - 4) * p
			nHeight = nHeight - 4
		else -- if d == "LEFT_RIGHT" then
			nWidth = (nWidth - 4) * p
			nHeight = nHeight - 4
		end

		sha:AppendCharacterID(self.dwID, true, r, g, b, a, { 0, 0, 0, bcX, bcY })
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, { 0, 0, 0, bcX + nWidth, bcY })
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, { 0, 0, 0, bcX + nWidth, bcY + nHeight })
		sha:AppendCharacterID(self.dwID, true, r, g, b, a, { 0, 0, 0, bcX, bcY + nHeight })
	end
	return self
end

-- ���Ѫ��
function HP:DrawLifeBar(nWidth, nHeight, nOffsetX, nOffsetY, rgbapd)
	return self:DrawRect(nWidth, nHeight, nOffsetX, nOffsetY, rgbapd, "hp_%s")
end

-- ������
function HP:DrawOTBar(nWidth, nHeight, nOffsetX, nOffsetY, rgbapd)
	return self:DrawRect(nWidth, nHeight, nOffsetX, nOffsetY, rgbapd, "ot_%s")
end
