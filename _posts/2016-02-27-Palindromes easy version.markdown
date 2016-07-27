---
layout: post
title:  "Palindromes easy version(2029)"
date:   2016-02-27 12:48:15 +0800
categories: HDOJ
---
### __问题描述__
> “回文串”是一个正读和反读都一样的字符串，比如“level”或者“noon”等等就是回文串。请写一个程序判断读入的字符串是否是“回文”。

### __输入要求__
> 输入包含多个测试实例，输入数据的第一行是一个正整数n，表示测试实例的个数，后面紧跟着是n个字符串。

### __输出要求__
> 如果一个字符串是回文串，则输出"yes"，否则输出"no"。

### __解题思路__
头下标置初值0，尾下标置初值长度减一，从字符串头和字符串尾同时向中间扫描，执行循环条件为头下标小于尾下标且头下标所指元素等于尾下标所指元素，跳出循环时若头下标不小于尾下标则为“回文”否则不是。

### __代码__
	#include <stdio.h>
	#include <string.h>

	int main()
	{
	    int n;
	    char s[101];
	    while(scanf("%d", &n) != EOF)
	    {
	        while(n--)
	        {
	            scanf("%s", s);
	            int i = 0, j = strlen(s) - 1;
	            while(i < j)
	            {
	                if(s[i] != s[j])
	                {
	                    break;
	                }
	                i++;
	                j--;
	            }
	            printf(i >= j ? "yes\n" : "no\n");
	        }
	    }
	    return 0;
	}