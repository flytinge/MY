# -*- coding: GBK -*-
import time, os
# ��ȡMY.lua�ļ��еĲ���汾��
szVersion = "0x0000000"
for line in open("MY_!Base/src/MY.lua"):
	if line[6:15] == "_VERSION_":
		szVersion = line[23:25]

# ��ȡ����ʽ����ǰʱ���ַ���
szTime = time.strftime("%Y%m%d%H%M%S", time.localtime())

# ƴ���ַ�����ʼѹ���ļ�
szFile = "!src-dist/releases/MY." + szTime + "v" + szVersion + ".7z"
print "zippping..."
os.system("7z a -t7z " + szFile + " -xr!manifest.dat -xr!manifest.key -xr!publisher.key -x@7zipignore.txt")
print "File(s) compressing acomplete!"
print "Url" + szFile

time.sleep(5)
