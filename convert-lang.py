# -*- coding: GBK -*-
from lang_mapping import map_zhcn2zhtw
import sys, os
import os.path # �����ļ������
import codecs  # ����UTF-8���������
import re      # ����ƥ��
import time    # ��ȡʱ��

def zhcn2zhtw(source):
	dest = ""
	pattern = re.compile(".", re.S) #u"([\u4e00-\u9fa5])"
	results =  pattern.findall(source)
	for result in results :
		if map_zhcn2zhtw.has_key(result):
			dest = dest + map_zhcn2zhtw[result]
		else:
			dest = dest + result
	return dest

rootdir = os.path.dirname(os.path.abspath(__file__))    # ָ�����������ļ���
for parent, dirnames, filenames in os.walk(rootdir):    # �����������ֱ𷵻�1.��Ŀ¼ 2.�����ļ������֣�����·���� 3.�����ļ�����
	if parent == "@DATA" or parent == ".git":
		continue
	#for dirname in  dirnames:                      #����ļ�����Ϣ
	#    print "parent is:" + parent
	#    print  "dirname is" + dirname

	for filename in filenames:                      #����ļ���Ϣ
		if filename == "zhcn.jx3dat":
			#print "parent is:" + parent
			#print "filename is:" + filename
			#print "the full name of the file is:" + os.path.join(parent,filename) #����ļ�·����Ϣ
			print 'file loading: ' + os.path.join(parent,filename)
			# all_the_text = "-- language data (zhtw) updated at " + time.strftime('%Y-%m-%d %H:%I:%M',time.localtime(time.time())) + "\r\n"
			all_the_text = ""
			for count, line in enumerate(codecs.open(os.path.join(parent,filename),'r',encoding='gbk')):
				if count == 0 and line.find('-- language data') == 0:
					all_the_text = line.replace('zhcn', 'zhtw')
					# pass
				else:
					all_the_text = all_the_text + line

			print 'file converting...'
			# all_the_text = all_the_text.decode('gbk')
			all_the_text = zhcn2zhtw(all_the_text)

			print 'file saving...'
			with codecs.open(os.path.join(parent,"zhtw.jx3dat"),'w',encoding='utf8') as f:
				f.write(all_the_text)
				print 'file saved: zhtw.jx3dat'
			print '-----------------------'
