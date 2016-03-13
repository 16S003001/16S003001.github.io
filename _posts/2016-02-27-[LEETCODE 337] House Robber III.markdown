---
layout: post
title:  "[LEETCODE 337] House Robber III"
date:   2016-03-13 10:42:55 +0800
categories: LEETCODE
---
### __问题描述__
> The thief has found himself a new place for his thievery again. There is only one entrance to this area, called the "root." Besides the root, each house has one and only one parent house. After a tour, the smart thief realized that "all houses in this place forms a binary tree". It will automatically contact the police if two directly-linked houses were broken into on the same night.

> Determine the maximum amount of money the thief can rob tonight without alerting the police.

> Example 1:

	     3
	    / \
	   2   3
	    \   \ 
	     3   1

> Maximum amount of money the thief can rob = 3 + 3 + 1 = 7.

> Example 2:

	     3
	    / \
	   4   5
	  / \   \ 
	 1   3   1

> Maximum amount of money the thief can rob = 4 + 5 = 9.

### __解题思路__
使用深度优先搜索DFS，对每个结点维护两个变量a、b，其中a表示小偷没有选择当前结点时所能获得的最大值，b表示小偷选择了当前结点时所能获得的最大值。

对一个没有子结点的结点M来说，a显然等于0，b则等于结点M的值。

对一个有子结点的结点N来说，a表示小偷没有选择当前结点时所能获得的最大值，那么结点N的子结点可以被小偷选中（对应于子结点的b）也可以不被小偷选中（对应于子结点的a），即可以取N的子结点的a、b中较大的值累加到a上；b表示小偷选择了当前结点时所能获得的最大值，由于当前结点N已经被小偷选中，那么显然N的子结点均不能被选中（对应于子结点的a），否则会触发警报，即只能取N的子结点的a累加到b上。

### __代码__
	/**
	 * Definition for a binary tree node.
	 * struct TreeNode {
	 *     int val;
	 *     struct TreeNode *left;
	 *     struct TreeNode *right;
	 * };
	 */
	 
	int Max(int a, int b)
	{
	    return a > b ? a : b;
	}

	void DFS(struct TreeNode* root, int *a, int *b)
	{
	    if(!root)
	    {
	        return;
	    }
	    if(root->left)
	    {
	        DFS(root->left, a, b);
	        int temp = *a;
	        *a = Max(*a, *b);
	        *b = temp;
	    }
	    if(root->right)
	    {
	        int a_temp = 0, b_temp = 0;
	        DFS(root->right, &a_temp, &b_temp);
	        *a += Max(a_temp, b_temp);
	        *b += a_temp;
	    }
	    *b += root->val;
	}

	int rob(struct TreeNode* root)
	{
	    int a = 0, b = 0;
	    DFS(root, &a, &b);
	    return Max(a, b);
	}