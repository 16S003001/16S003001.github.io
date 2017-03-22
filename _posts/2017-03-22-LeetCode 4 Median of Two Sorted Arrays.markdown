---
layout: post
title: "LeetCode 4 Median of Two Sorted Arrays"
author: '#1121'
date: 2017-03-22 16:07:38 +0800
categories: [分治法]
---

[题目点这里](https://leetcode.com/problems/median-of-two-sorted-arrays/#/description)

这里要求了时间复杂度要低于O(log(m+n))，显然很容易想到使用分治法，每次递归将子问题的规模缩小一半。

## 思路

给定的两个数组已经是有序的，要求的是两个数组合并在一起并排序后的中位数，若两个数组的长度为别为m+n，那么问题就可以很容易地转换为求合并后的数组中第**⎡(m+n)/2⎤小的数（m+n为奇数时，当m+n为偶数时相应地变为第(m+n)/2小和第(m+n+2)/2小的数之和的平均值）**。即转换为求两个数组中第k小的数的问题，显然当k为1的时候直接返回两个数组中第一个元素的较小的值即可，那么我们如何将k逐渐缩小到1呢？

基于题目给定的复杂度，想到的首先就是每次递归将k缩小一半，所以在这里引入一个下标k/2-1记做i，然后分别取两个数组中下标为i的值（记做A和B）进行比较：

* 若A<B，A和B左侧均有k/2-1个元素，由于A<B，因此至多有k-2个（**在这里只是简单分析下，不考虑k的奇偶性**）元素小于A，即A在整体中最大也只能是第k-1小的元素，因此显然我们可以将A及A左侧的元素全部移除，这样做的意义在于我们已经找到了第k小的元素前的k/2个元素，接下来需要做的就是在移除后的数组中寻找第k-k/2小的元素即可，通过这一过程，每次递归k都会减小为原来的一半。
* 若A>B，和上面是同样的道理，只不过移除的是B以及B之前的元素。
* 若A=B，同样地，小于A和B的元素个数均是k-2，因此二者中有一个仍被填充到第k-1小的位置（或者更小，这是由于k的奇偶性导致的），而另一个是有可能成为第k小的元素的，因此这时我们可以选择将A及A左侧的元素全部移除或是将B及B左侧的元素全部移除。

这里需要考虑一些边界，比如两个数组中的一个通过之前的移除操作其长度已经小于k/2，那么我们以将该数组对应的A或B置为正无穷继续和另一个值进行比较，这是出于这样的考虑：假如A为某一值而B为正无穷，那么显然会导致A<B，此时B对应的数组的长度小于k/2，而即使这些元素全部小于A，小于A的元素的个数最多仍然只能达到k-2，因此仍然可以将A及其左侧的元素移除。

## 代码

{% highlight bash linenos %}
public double findMedianSortedArrays(int[] nums1, int[] nums2) {
    int l1 = nums1.length;
    int l2 = nums2.length;

    int k1 = (l1 + l2 + 1) / 2;
    int k2 = (l1 + l2 + 2) / 2;
    return (findKthSortedArrays(nums1, 0, nums2, 0, k1) + findKthSortedArrays(nums1, 0, nums2, 0, k2)) / 2;
}


public double findKthSortedArrays(int[] nums1, int start1, int[] nums2, int start2, int k) {
    if (start1 >= nums1.length) {
        return nums2[start2 + k - 1];
    }
    if (start2 >= nums2.length) {
        return nums1[start1 + k - 1];
    }
    if (k == 1) {
        return Math.min(nums1[start1], nums2[start2]);
    }

    int mid1 = Integer.MAX_VALUE;
    int mid2 = Integer.MAX_VALUE;

    if (start1 + k / 2 - 1 < nums1.length) {
        mid1 = nums1[start1 + k / 2 - 1];
    }
    if (start2 + k / 2 - 1 < nums2.length) {
        mid2 = nums2[start2 + k / 2 - 1];
    }

    if (mid1 < mid2) {
        return findKthSortedArrays(nums1, start1 + k / 2, nums2, start2, k - k / 2);
    } else {
        return findKthSortedArrays(nums1, start1, nums2, start2 + k / 2, k - k / 2);
    }
}
{% endhighlight %}

## 时间复杂度

在上面的算法中，每回合将k缩小为原来的一半，每一轮迭代中，除了求解子问题外，其他部分操作可以在常数时间内完成，所以建立的递归方程如下：

> T(s)  = T(s/2)+1
        = T(s/2²)+2
        = ...
        = T(s/2ᴷ)+k

当s/2ᴷ=1时可以解得k=log(s)，所以T(s)=O(logs)，又因为s与m+n是线性关系，若以T(s)=O(log(m+n))。