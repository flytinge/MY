--------------------------------------------
-- @Desc  : ��Ϸ����
-- @Author: ��һ�� @tinymins
-- @Date  : 2015-02-28 17:37:53
-- @Email : admin@derzh.com
-- @Last Modified by:   ��һ�� @tinymins
-- @Last Modified time: 2015-03-01 00:13:27
--------------------------------------------
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot .. "MY_Font/lang/")
local C = {
	tFontList = Font.GetFontPathList() or {},
	tFontType = {
		{ dwID = Font.GetChatFontID(), szName = _L['chat'] }
	},
}
local OBJ = {}

function OBJ.SetFont(dwID, szName, szPath, nSize, tTable)
	-- dwID  : Ҫ�ı���������ͣ�����/�ı�/���� �ȣ�
	-- szName: ��������
	-- szPath: ����·��
	-- nSize : �����С
	-- tTable: {
	--     ["vertical"] = (bool),
	--     ["border"  ] = (bool),
	--     ["shadow"  ] = (bool),
	--     ["mono"    ] = (bool),
	--     ["mipmap"  ] = (bool),
	-- }
	-- Ex: SetFont(Font.GetChatFontID(), "����", "\\UI\\Font\\��������_GBK.ttf", 16, {["shadow"] = true})
	Font.SetFont(dwID, szName, szPath, nSize, tTable)
	Station.SetUIScale(Station.GetUIScale(), true)
end

MY.RegisterPanel(
"MY_Font", _L["MY_Font"], _L['Development'],
"ui/Image/UICommon/BattleFiled.UITex|7", {255,127,0,200}, {
OnPanelActive = function(wnd)
	local ui = MY.UI(wnd)
	local x, y = 10, 30
	
end})

MY_Font = OBJ
