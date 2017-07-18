# -*- coding: GBK -*-
import time, os, re

# ��ȡMY.lua�ļ��еĲ���汾��
str_version = "0x0000000"
for line in open("MY_!Base/src/MY.lua"):
	if line[6:15] == "_VERSION_":
		str_version = line[23:25]

# ��ȡGit�����İ汾��
version_list = os.popen('git tag').read().strip().split("\n")
max_version, git_tag = 0, ''
for version in version_list:
	if max_version < int(version[1:]):
		git_tag = version
		max_version = int(version[1:])

# �ж��Ƿ����������汾��
if int(str_version) <= max_version:
	print 'Error: current version(%s) is smaller than or equals with last git published version(%d)!' % (str_version, max_version)
	exit()

# ��ȡGit�����İ汾�� �����°��޸��ļ�
paths = {}
if git_tag != '':
	filelist = os.popen('git diff ' + git_tag + ' --name-status').read().strip().split("\n")
	for file in filelist:
		paths[re.sub('["/].*$', '', re.sub('^[^\t]\t"*', '', file))] = True

# ƴ���ַ�����ʼѹ���ļ�
dst_file = "!src-dist/releases/MY." + time.strftime("%Y%m%d%H%M%S", time.localtime()) + "v" + str_version + ".7z"
print "zippping..."
cmd = "7z a -t7z " + dst_file + " -xr!manifest.dat -xr!manifest.key -xr!publisher.key -x@7zipignore.txt"
for path in paths:
	cmd = cmd + ' "' + path + '"'
os.system(cmd)
print "Based on git tag " + git_tag + "."
print "File(s) compressing acomplete!"
print "Url: " + dst_file

time.sleep(5)
