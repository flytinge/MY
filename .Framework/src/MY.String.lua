---------------------------------
-- �������
-- by������@˫����@׷����Ӱ
-- ref: �����������Դ�� @haimanchajian.com
---------------------------------
-----------------------------------------------
-- ���غ����ͱ���
-----------------------------------------------
MY = MY or {}
MY.String = MY.String or {}
MY.String.Split = function(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end
MY.String.PatternEscape = function(s) return (string.gsub(s, '([%(%)%.%%%+%-%*%?%[%^%$%]])', '%%%1')) end
MY.String.UrlEncode = function(w)
    pattern="[^%w%d%._%-%* ]"
    local s=string.gsub(w,pattern,function(c)
        local c=string.format("%%%02X",string.byte(c))
        return c
    end)
    s=string.gsub(s," ","+")
    return s
end
MY.String.LenW = function(str)
    return #(string.gsub(str, '[\128-\255][\128-\255]', ' '))
end
MY.String.SubW = function(str,s,e)
    str=str:gsub('([\001-\127])','\000%1')
    s = s and ((s>=0 and s*2-1) or s*2)
    e = e and ((e>=0 and e*2) or e*2+1)
    str = str:sub(s, e)
    str = str:gsub('\000','')
    return str
end