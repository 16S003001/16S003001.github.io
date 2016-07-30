import time

# time format
timeformat_file = '%Y-%m-%d-'
timeformat_title = '%Y-%m-%d %X'

# input title of the blog
title = raw_input('Input title: ')

# author of the blog
author = 'Guomato'

# input categories of the blog, end input with '#'
categories = []
while 1:
	category = raw_input('Input category(end with #): ')
	if(category == '#'):
		break
	categories.append(category)

# obtain the time when blog created
localtime = time.localtime(time.time())

# obtain file path of the blog
path = '_posts/' + time.strftime(timeformat_file, localtime) + title + '.markdown'

# obtain initial content of the blog according to title, time and categories
content = '---\nlayout: post\ntitle: \"' + title + '\"\nauthor: ' + author + '\ndate: ' + time.strftime(timeformat_title, localtime) + ' +0800\ncategories:'
for category in categories:
	content += ' ' + category
content += '\n---'

# create blog file
file = open(path, 'w')
file.write(content)
file.close

print 'Blog generated successfully.'