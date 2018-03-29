--------------------------------------------
-- @Desc  : ������� - ��ѧ��
-- @Author: ���� @˫���� @׷����Ӱ
-- @Date  : 2015-02-15 09:36:13
-- @Email : admin@derzh.com
-- @Last Modified by:   ���� @tinymins
-- @Last Modified time: 2016-02-02 16:47:28
-- @Ref: �����������Դ�� @haimanchajian.com
--------------------------------------------
MY = MY or {}
MY.Math = MY.Math or {}
local _C = {}
local tinsert, tremove = table.insert, table.remove

-- (table) Number2Bitmap(number n)
-- ��һ����ֵת����һ��Bit����λ��ǰ ��λ�ں�
do
local metatable = { __index = function() return 0 end }
function _C.Number2Bitmap(n)
	local t = {}
	if n == 0 then
		tinsert(t, 0)
	else
		while n > 0 do
			local nValue = math.fmod(n, 2)
			tinsert(t, nValue)
			n = math.floor(n / 2)
		end
	end
	return setmetatable(t, metatable)
end
MY.Math.Number2Bitmap = _C.Number2Bitmap
end

-- (number) Bitmap2Number(table t)
-- ��һ��Bit��ת����һ����ֵ����λ��ǰ ��λ�ں�
function _C.Bitmap2Number(t)
	local n = 0
	for i, v in pairs(t) do
		if type(i) == 'number' and v and v ~= 0 then
			n = n + 2 ^ (i - 1)
		end
	end
	return n
end
MY.Math.Bitmap2Number = _C.Bitmap2Number

-- (number) SetBit(number n, number i, bool/0/1 b)
-- ����һ����ֵ��ָ������λ
function MY.Math.SetBit(n, i, b)
	n = n or 0
	local t = _C.Number2Bitmap(n)
	if b and b ~= 0 then
		t[i] = 1
	else
		t[i] = 0
	end
	return _C.Bitmap2Number(t)
end

-- (0/1) GetBit(number n, number i)
-- ��ȡһ����ֵ��ָ������λ
function MY.Math.GetBit(n, i)
	return _C.Number2Bitmap(n)[i] or 0
end

-- (number) BitAnd(number n1, number n2)
-- ��λ������
function MY.Math.BitAnd(n1, n2)
	local t1 = _C.Number2Bitmap(n1)
	local t2 = _C.Number2Bitmap(n2)
	local t3 = {}
	for i = 1, math.max(#t1, #t2) do
		t3[i] = t1[i] == 1 and t2[i] == 1 and 1 or 0
	end
	return _C.Bitmap2Number(t3)
end

-- (number) BitOr(number n1, number n2)
-- ��λ������
function MY.Math.BitOr(n1, n2)
	local t1 = _C.Number2Bitmap(n1)
	local t2 = _C.Number2Bitmap(n2)
	local t3 = {}
	for i = 1, math.max(#t1, #t2) do
		t3[i] = t1[i] == 0 and t2[i] == 0 and 0 or 1
	end
	return _C.Bitmap2Number(t3)
end

-- (number) BitXor(number n1, number n2)
-- ��λ�������
function MY.Math.BitXor(n1, n2)
	local t1 = _C.Number2Bitmap(n1)
	local t2 = _C.Number2Bitmap(n2)
	local t3 = {}
	for i = 1, math.max(#t1, #t2) do
		t3[i] = t1[i] == t2[i] and 0 or 1
	end
	return _C.Bitmap2Number(t3)
end
