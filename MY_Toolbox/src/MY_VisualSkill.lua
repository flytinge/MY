--------------------------------------------
-- @Desc  : ������ʾ - ս�����ӻ�
-- @Author: ��һ�� @tinymins
-- @Date  : 2015-03-02 10:08:45
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2017-05-05 18:15:10
--------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."MY_Toolbox/lang/")
local _C = {}
local INI_PATH = MY.GetAddonInfo().szRoot .. "MY_ToolBox/ui/MY_VisualSkill.ini"
local BOX_W = 55
local ANI_TIME = 450
local OUT_DISTANCE = 200
local defaultAnchor = {x = 0, y = -220, s = "BOTTOMCENTER", r = "BOTTOMCENTER"}
MY_VisualSkill = {}
MY_VisualSkill.bEnable = false
MY_VisualSkill.bPenetrable = true
MY_VisualSkill.anchorVisualSkill = defaultAnchor
MY_VisualSkill.nVisualSkillBoxCount = 5
RegisterCustomData("MY_VisualSkill.bEnable")
RegisterCustomData("MY_VisualSkill.bPenetrable")
RegisterCustomData("MY_VisualSkill.anchorVisualSkill")
RegisterCustomData("MY_VisualSkill.nVisualSkillBoxCount")

local function ApplyAnchor(frame)
	frame:SetPoint(defaultAnchor.s, 0, 0, defaultAnchor.r, defaultAnchor.x, defaultAnchor.y)
	frame:CorrectPos()
end

local function GetRealIndex(nIndex, nIndexBase, nCount)
	return (nIndex + nIndexBase) % nCount
end

local function UpdateUI(frame, during)
	local percentage = math.min(math.max(during / ANI_TIME, 0), 1)
	local hList = frame:Lookup("", "Handle_Boxes")
	local nCount = hList:GetItemCount()
	
	local nFirstIndex = GetRealIndex(0, frame.nIndexBase, nCount)
	hList:Lookup(nFirstIndex):SetAlpha((1 - percentage) * 255)
	hList:Lookup(nFirstIndex):SetRelX(-OUT_DISTANCE * percentage)
	
	local nLeftW = 0
	for i = 1, nCount - 2 do
		local hItem = hList:Lookup(GetRealIndex(i, frame.nIndexBase, nCount))
		hItem:SetAlpha(255)
		hItem:SetRelX(nLeftW + BOX_W * (1 - percentage))
		nLeftW = nLeftW + hItem:GetW()
	end
	
	local nLastIndex = GetRealIndex(nCount - 1, frame.nIndexBase, nCount)
	hList:Lookup(nLastIndex):SetAlpha(percentage * 255)
	hList:Lookup(nLastIndex):SetRelX(nLeftW + OUT_DISTANCE * (1 - percentage))
	
	hList:FormatAllItemPos()
end

local function DrawUI(frame)
	local hList = frame:Lookup("", "Handle_Boxes")
	local nOffset = MY_VisualSkill.nVisualSkillBoxCount - hList:GetItemCount() + 1
	if nOffset == 0 then
		return
	elseif nOffset > 0 then
		for i = 1, nOffset do
			hList:AppendItemFromIni(INI_PATH, "Handle_Box"):Lookup("Box_Skill"):Hide()
		end
	elseif nOffset < 0 then
		for i = nOffset, -1 do
			hList:RemoveItem(frame.nIndexBase)
			frame.nIndexBase = (frame.nIndexBase + 1) % hList:GetItemCount()
		end
	end
	local nBoxesW = BOX_W * MY_VisualSkill.nVisualSkillBoxCount
	frame:Lookup("", "Handle_Bg/Image_Bg_11"):SetW(nBoxesW - 34)
	frame:Lookup("", "Handle_Bg"):FormatAllItemPos()
	frame:Lookup("", ""):FormatAllItemPos()
	frame:SetW(nBoxesW + 176)
	hList:SetW(nBoxesW)
	UpdateUI(frame, ANI_TIME)
end

local function OnSkillCast(frame, dwSkillID, dwSkillLevel)
	-- get name
	local szSkillName, dwIconID = MY.Player.GetSkillName(dwSkillID, dwSkillLevel)
	if dwSkillID == 4097 then -- ���
		dwIconID = 1899
	elseif Table_IsSkillFormation(dwSkillID, dwSkillLevel)        -- �󷨼���
		or Table_IsSkillFormationCaster(dwSkillID, dwSkillLevel)  -- ���ͷż���
		-- or dwSkillID == 230     -- (230)  ���˺���ʩ��  �߾���ң��
		-- or dwSkillID == 347     -- (347)  ����������ʩ��  �Ź�������
		-- or dwSkillID == 526     -- (526)  ����������ʩ��  ���������
		-- or dwSkillID == 662     -- (662)  ��߷������ͷ�  ���������
		-- or dwSkillID == 740     -- (740)  ���ַ�����ʩ��  ��շ�ħ��
		-- or dwSkillID == 745     -- (745)  ���ֹ�����ʩ��  ���������
		-- or dwSkillID == 754     -- (754)  ��߹������ͷ�  �����۳���
		-- or dwSkillID == 778     -- (778)  ����������ʩ��  ����������
		-- or dwSkillID == 781     -- (781)  �����˺���ʩ��  ����������
		-- or dwSkillID == 1020    -- (1020) ��������ʩ��  ���Ǿ�����
		-- or dwSkillID == 1866    -- (1866) �ؽ����ͷ�      ��ɽ������
		-- or dwSkillID == 2481    -- (2481) �嶾������ʩ��  ����֯����
		-- or dwSkillID == 2487    -- (2487) �嶾������ʩ��  ���������
		-- or dwSkillID == 3216    -- (3216) �����⹦��ʩ��  ���Ǹ�����
		-- or dwSkillID == 3217    -- (3217) �����ڹ���ʩ��  ǧ���ٱ���
		-- or dwSkillID == 4674    -- (4674) ���̹�����ʩ��  ������ħ��
		-- or dwSkillID == 4687    -- (4687) ���̷�����ʩ��  ����������
		-- or dwSkillID == 5311    -- (5311) ؤ�﹥�����ͷ�  ����������
		-- or dwSkillID == 13228   -- (13228)  �ٴ���ɽ���ͷ�  �ٴ���ɽ��
		-- or dwSkillID == 13275   -- (13275)  ��������ʩ��  ��������
		or dwSkillID == 10         -- (10)    ��ɨǧ��           ��ɨǧ��
		or dwSkillID == 11         -- (11)    ��ͨ����-������    ���Ϲ�
		or dwSkillID == 12         -- (12)    ��ͨ����-ǹ����    ÷��ǹ��
		or dwSkillID == 13         -- (13)    ��ͨ����-������    ���񽣷�
		or dwSkillID == 14         -- (14)    ��ͨ����-ȭ�׹���  ��ȭ
		or dwSkillID == 15         -- (15)    ��ͨ����-˫������  ����˫��
		or dwSkillID == 16         -- (16)    ��ͨ����-�ʹ���    �йٱʷ�
		or dwSkillID == 1795       -- (1795)  ��ͨ����-�ؽ�����  �ļ�����
		or dwSkillID == 2183       -- (2183)  ��ͨ����-��ѹ���  ��ĵѷ�
		or dwSkillID == 3121       -- (3121)  ��ͨ����-������    ��ڷ�
		or dwSkillID == 4326       -- (4326)  ��ͨ����-˫������  ��Į����
		or dwSkillID == 13039      -- (13039) ��ͨ����_�ܵ�����  ��ѩ��
		or dwSkillID == 16010      -- (16010) ��ͨ����_��˪������  ˪�絶��
		or dwSkillID == 17         -- (17)    ����-��������-���� ����
		or dwSkillID == 18         -- (18)    ̤�� ̤��
		or dwIconID  == 1817       -- ����
		or dwIconID  == 533        -- ����
		or dwIconID  == 13         -- �Ӽ���
		or not szSkillName
		or szSkillName == ""
	then
		return
	end
	
	local hList = frame:Lookup("", "Handle_Boxes")
	local hItem = hList:Lookup(frame.nIndexBase)
	frame.nIndexBase = (frame.nIndexBase + 1) % hList:GetItemCount()
	
	local box = hItem:Lookup("Box_Skill")
	box:SetObject(UI_OBJECT_SKILL, dwSkillID, dwSkillLevel)
	box:SetObjectIcon(dwIconID)
	box:Show()
	
	frame.nTickStart = GetTickCount()
end

function MY_VisualSkill.OnFrameCreate()
	this.nIndexBase = 0
	DrawUI(this)
	this:RegisterEvent("RENDER_FRAME_UPDATE")
	this:RegisterEvent("UI_SCALED")
	this:RegisterEvent("DO_SKILL_CAST")
	this:RegisterEvent("ON_ENTER_CUSTOM_UI_MODE")
	this:RegisterEvent("ON_LEAVE_CUSTOM_UI_MODE")
	this:RegisterEvent("CUSTOM_UI_MODE_SET_DEFAULT")
	MY_VisualSkill.OnEvent("UI_SCALED")
end

function MY_VisualSkill.OnEvent(event)
	if event == "RENDER_FRAME_UPDATE" then
		if not this.nTickStart then
			return
		end
		local nTickDuring = GetTickCount() - this.nTickStart
		if nTickDuring > 600 then
			this.nTickStart = nil
		end
		UpdateUI(this, nTickDuring)
	elseif event == "UI_SCALED" then
		ApplyAnchor(this)
	elseif event == "DO_SKILL_CAST" then
		local dwID, dwSkillID, dwSkillLevel = arg0, arg1, arg2
		if dwID == GetControlPlayer().dwID then
			OnSkillCast(this, dwSkillID, dwSkillLevel)
		end
	elseif event == "ON_ENTER_CUSTOM_UI_MODE" then
		UpdateCustomModeWindow(this, szTip, MY_VisualSkill.bPenetrable)
	elseif event == "ON_LEAVE_CUSTOM_UI_MODE" then
		UpdateCustomModeWindow(this, szTip, MY_VisualSkill.bPenetrable)
	elseif event == "CUSTOM_UI_MODE_SET_DEFAULT" then
		MY_VisualSkill.anchorVisualSkill = defaultAnchor
		ApplyAnchor(this)
	end
end

function MY_VisualSkill.Open()
	Wnd.OpenWindow(INI_PATH, "MY_VisualSkill")
end

function MY_VisualSkill.GetFrame()
	return Station.Lookup("Normal/MY_VisualSkill")
end

function MY_VisualSkill.Close()
	Wnd.CloseWindow("MY_VisualSkill")
end

function MY_VisualSkill.Reload()
	if MY_VisualSkill.bEnable then
		local frame = MY_VisualSkill.GetFrame()
		if frame then
			DrawUI(frame)
		else
			MY_VisualSkill.Open()
		end
	else
		MY_VisualSkill.Close()
	end
end
MY.RegisterInit('MY_VISUALSKILL', MY_VisualSkill.Reload)
