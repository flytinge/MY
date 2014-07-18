----------------------------------------------------
-- ������ͼ���� ver 0.2 Build 20140717
-- Code by: ��һ��tinymins @ ZhaiYiMing.CoM
-- ���塤˫��������
---------------------------------------------------
local _GLOBAL_CONFIG_ = MY.GetAddonInfo().szRoot.."MY_ScreenShot/data/Global.dat"
local _L = MY.LoadLangPack(MY.GetAddonInfo().szRoot.."ScreenShot/lang/")
local _MY_ScreenShot = {}
MY_ScreenShot = MY_ScreenShot or {}
MY_ScreenShot.Const = {}
MY_ScreenShot.Const.SHOW_UI = 1
MY_ScreenShot.Const.HIDE_UI = 2
MY_ScreenShot.globalConfig = {
    szFileExName = "jpg",
    nQuality = 100,
    bAutoHideUI = false,
    szFilePath = "./ScreenShot/",
}
MY_ScreenShot.globalConfig = LoadLUAData(_GLOBAL_CONFIG_) or MY_ScreenShot.globalConfig
MY_ScreenShot.bUseGlobalConfig = true
MY_ScreenShot.privateConfig = {
    szFileExName = "jpg",
    nQuality = 100,
    bAutoHideUI = false,
    szFilePath = "./ScreenShot/",
}
RegisterCustomData("MY_ScreenShot.bUseGlobalConfig")
for k, _ in pairs(MY_ScreenShot.privateConfig) do
    RegisterCustomData("MY_ScreenShot.privateConfig." .. k)
end
-- ȡ����
MY_ScreenShot.SetConfig = function(szKey, oValue)
    if MY_ScreenShot.bUseGlobalConfig then
        MY_ScreenShot.globalConfig[szKey] = oValue
        SaveLUAData(_GLOBAL_CONFIG_)
    else
        MY_ScreenShot.privateConfig[szKey] = oValue
    end
end
-- ������
MY_ScreenShot.GetConfig = function(szKey)
    if MY_ScreenShot.bUseGlobalConfig then
        return MY_ScreenShot.globalConfig[szKey]
    else
        return MY_ScreenShot.privateConfig[szKey]
    end
end
_MY_ScreenShot.ShotScreen = function(szFilePath, nQuality ,bFullPath)Output(szFilePath, nQuality, bFullPath)
    local szFullPath = ScreenShot(szFilePath, nQuality, bFullPath)
    MY.Sysmsg("��ͼ�ɹ����ļ��ѱ��棺"..szFullPath.."\n")
end
MY_ScreenShot.ShotScreen = function(nShowUI)
    -- ���ɿ�ʹ�õ�������ͼĿ¼
    local szFolderPath = MY_ScreenShot.GetConfig("szFilePath")
    if not IsFileExist(szFolderPath) then
        MY.Sysmsg("��ͼ�ļ������ô���"..szFolderPath.."Ŀ¼�����ڡ���ͼ�����浽Ĭ���ļ��С�\n")
        szFolderPath = "./ScreenShot/"
    end
    -- �����ļ�����·������
    local tDateTime = TimeToDate(GetCurrentTime())
    local szFilePath
    local i = 0
    repeat
        szFilePath = szFolderPath .. (string.format("%04d-%02d-%02d_%02d-%02d-%02d-%03d", tDateTime.year, tDateTime.month, tDateTime.day, tDateTime.hour, tDateTime.minute, tDateTime.second, i)) .."." .. MY_ScreenShot.GetConfig("szFileExName")
        i=i+1
    until not IsFileExist(szFilePath)
    -- ����nShowUI��ͬ��ʽʵ�ֽ�ͼ
    local bStationVisible = Station.IsVisible()
    if nShowUI == MY_ScreenShot.Const.HIDE_UI and bStationVisible then
        Station.Hide()
        MY.DelayCall(function()
            _MY_ScreenShot.ShotScreen(szFilePath, MY_ScreenShot.GetConfig('nQuality'), true)
            Station.Show()
        end,100)
    elseif nShowUI == MY_ScreenShot.Const.SHOW_UI and not bStationVisible then
        Station.Show()
        MY.DelayCall(function()
            _MY_ScreenShot.ShotScreen(szFilePath, MY_ScreenShot.GetConfig('nQuality'), true)
            Station.Hide()
        end,100)
    else
        _MY_ScreenShot.ShotScreen(szFilePath, MY_ScreenShot.GetConfig('nQuality'), true)
    end
end
-- ע��INIT�¼�
MY.RegisterInit(function()
    MY.BreatheCall("MY_ScreenShot_Hotkey_Check", function()
        local nKey, nShift, nCtrl, nAlt = MY.Game.GetHotKey("MY_ScreenShot_Hotkey")
        if type(nKey)=="nil" or nKey==0 then
            MY.Game.SetHotKey("MY_ScreenShot_Hotkey",1,44,false,false,false)
        end
    end, 10000)
end)
-- ��ǩ������
_MY_ScreenShot.OnPanelActive = function(wnd)
    local ui = MY.UI(wnd)
    local fnRefreshPanel = function(ui)
        ui:children("#WndCheckBox_HideUI"):check(MY_ScreenShot.GetConfig('bAutoHideUI'))
        ui:children("#WndCombo_FileExName"):text(MY_ScreenShot.GetConfig("szFileExName"))
        ui:children("#WndTrackBar_Quality"):value(MY_ScreenShot.GetConfig("nQuality"))
        
    end
    
    ui:append("WndCheckBox_UseGlobal", "WndCheckBox"):children("#WndCheckBox_UseGlobal"):pos(10,10)
      :text(_L["ʹ�������˺�ȫ���趨"]):tip(_L['��ѡ������ý�ɫʹ�ù����趨��ȡ����ѡ��ý�ɫʹ�õ����趨��'])
      :check(function() MY_ScreenShot.bUseGlobalConfig = not MY_ScreenShot.bUseGlobalConfig end)
      :check(MY_ScreenShot.bUseGlobalConfig)
    
    ui:append("WndCheckBox_HideUI", "WndCheckBox"):children("#WndCheckBox_HideUI"):pos(10,40)
      :text(_L['��ͼ�Զ�����UI']):tip(_L['��ѡ�������ͼʱ�Զ�����UI��'])
      :check(function(bChecked) MY_ScreenShot.SetConfig("bAutoHideUI", bChecked) end)
      :check(MY_ScreenShot.GetConfig("bAutoHideUI"))
      
    ui:append("Text_FileExName", "Text"):find("#Text_FileExName"):text(_L['��ͼ��ʽ']):pos(10,70)
    ui:append('WndCombo_FileExName','WndComboBox'):children('#WndCombo_FileExName'):pos(80,70):width(80)
      :menu(function()
        return {
            {szOption = "jpg", bChecked = MY_ScreenShot.GetConfig("szFileExName")=="jpg", rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() MY_ScreenShot.SetConfig("szFileExName", "jpg") end, fnAutoClose = function() return true end},
            {szOption = "png", bChecked = MY_ScreenShot.GetConfig("szFileExName")=="png", rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() MY_ScreenShot.SetConfig("szFileExName", "png") end, fnAutoClose = function() return true end},
            {szOption = "bmp", bChecked = MY_ScreenShot.GetConfig("szFileExName")=="bmp", rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() MY_ScreenShot.SetConfig("szFileExName", "bmp") end, fnAutoClose = function() return true end},
            {szOption = "tga", bChecked = MY_ScreenShot.GetConfig("szFileExName")=="tga", rgb = GetMsgFontColor("MSG_SYS", true), fnAction = function() MY_ScreenShot.SetConfig("szFileExName", "tga") end, fnAutoClose = function() return true end},
        }
      end)
      :text(MY_ScreenShot.GetConfig("szFileExName"))
    
    ui:append("Text_Quality", "Text"):find("#Text_Quality"):text(_L['���ý�ͼ����(0-100)']):pos(10,100)
    ui:append("WndSliderBox_Quality", "WndSliderBox"):children("#WndSliderBox_Quality"):pos(10,130)
      :sliderStyle(false):range(0, 100)
      :tip(_L['���ý�ͼ����(0-100)��Խ��Խ������ͼƬҲ��Խռ�ռ䡣'])
      :change(function(nValue) MY_ScreenShot.SetConfig('nQuality', nValue) end)
    
    ui:append("Text_SsRoot", "Text"):find("#Text_SsRoot"):text(_L['ͼƬ�ļ��У�']):pos(10,170)
    ui:append("WndEditBox_SsRoot", "WndEditBox"):children("#WndEditBox_SsRoot"):pos(110,170):size(400,20)
      :text(MY_ScreenShot.GetConfig("szFilePath"))
      :change(function(szValue)
        szValue = string.gsub(szValue, "^%s*(.-)%s*$", "%1")
        szValue = string.gsub(szValue, "^(.-)[\/]*$", "%1")..'/'
        MY_ScreenShot.SetConfig("szFilePath", szValue)
      end)
      :tip(_L['���ý�ͼ�ļ��У���ͼ�ļ������浽���õ�Ŀ¼�У�֧�־���·�������·�������·������/bin/zhcn/��\nע��Ϊ����ָ�Ĭ���ļ���'],MY.Const.UI.Tip.POS_TOP)
    
end
-- ��ݼ���
-----------------------------------------------
MY.Game.AddHotKey("MY_ScreenShot_Hotkey", "��ͼ������", function() MY_ScreenShot.ShotScreen(-1) end, nil)
MY.Game.AddHotKey("MY_ScreenShot_Hotkey_HideUI", "����UI��ͼ������", function() MY_ScreenShot.ShotScreen(0) end, nil)
MY.Game.AddHotKey("MY_ScreenShot_Hotkey_ShowUI", "��ʾUI��ͼ������", function() MY_ScreenShot.ShotScreen(1) end, nil)
MY.RegisterPanel( "ScreenShot", _L["screenshot helper"], "UI/Image/Minimap/Minimap.UITex|197", {255,127,0,200}, { OnPanelActive = _MY_ScreenShot.OnPanelActive, OnPanelDeactive = nil } )
