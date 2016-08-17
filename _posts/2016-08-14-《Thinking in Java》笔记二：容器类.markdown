---
layout: post
title: "《Thinking in Java》笔记二：容器类"
author: Guomato
date: 2016-08-14 14:17:10 +0800
categories: [Java, 《Thinking in Java》笔记]
---

Java容器类的用途是“保存对象”，可划分为如下两个不同的概念：

* Collection，一个独立对象元素的序列，包括List、Set以及Queue。
* Map，一组成对的键值对对象，允许使用键来查找值。

{% highlight bash linenos %}
public class PrintingContainers {

	static Collection<String> fill(Collection<String> collection) {
		collection.add("rat");
		collection.add("cat");
		collection.add("dog");
		collection.add("dog");
		return collection;
	}
	
	static Map<String, String> fill(Map<String, String> map) {
		map.put("rat", "Fuzzy");
		map.put("cat", "Rags");
		map.put("dog", "Bosco");
		map.put("dog", "Spot");
		return map;
	}
	
	public static void main(String[] args) {
		print(fill(new ArrayList<String>()));
		print(fill(new LinkedList<String>()));
		print(fill(new HashSet<String>()));
		print(fill(new TreeSet<String>()));
		print(fill(new LinkedHashSet<String>()));
		print(fill(new HashMap<String, String>()));
		print(fill(new TreeMap<String, String>()));
		print(fill(new LinkedHashMap<String, String>()));
	}
	
}

//运行结果
[rat, cat, dog, dog]
[rat, cat, dog, dog]
[rat, cat, dog]
[cat, dog, rat]
[rat, cat, dog]
{rat=Fuzzy, cat=Rags, dog=Spot}
{cat=Rags, dog=Spot, rat=Fuzzy}
{rat=Fuzzy, cat=Rags, dog=Spot}
{% endhighlight %}

下面对一些常用的容器类进行介绍。

#### __ArrayList__

ArrayList是长度可变的动态数组，从上面的运行结果中，我们可以看到，ArrayList具有如下特性：

* ArrayList储存元素的顺序即元素被添加的顺序
* ArrayList可以添加重复的元素
* ArrayList可以添加为null的元素（这一点在上面的例子中未作说明）

先来看ArrayList提供的三个构造器：

{% highlight bash linenos %}
/**
 * Constructs an empty list with the specified initial capacity.
 *
 * @param  initialCapacity  the initial capacity of the list
 * @throws IllegalArgumentException if the specified initial capacity
 *         is negative
 */
public ArrayList(int initialCapacity) {
    if (initialCapacity > 0) {
        this.elementData = new Object[initialCapacity];
    } else if (initialCapacity == 0) {
        this.elementData = EMPTY_ELEMENTDATA;
    } else {
        throw new IllegalArgumentException("Illegal Capacity: "+
                                           initialCapacity);
    }
}

/**
 * Constructs an empty list with an initial capacity of ten.
 */
public ArrayList() {
    this.elementData = DEFAULTCAPACITY_EMPTY_ELEMENTDATA;
}

/**
 * Constructs a list containing the elements of the specified
 * collection, in the order they are returned by the collection's
 * iterator.
 *
 * @param c the collection whose elements are to be placed into this list
 * @throws NullPointerException if the specified collection is null
 */
public ArrayList(Collection<? extends E> c) {
    elementData = c.toArray();
    if ((size = elementData.length) != 0) {
        // c.toArray might (incorrectly) not return Object[] (see 6260652)
        if (elementData.getClass() != Object[].class)
            elementData = Arrays.copyOf(elementData, size, Object[].class);
    } else {
        // replace with empty array.
        this.elementData = EMPTY_ELEMENTDATA;
    }
}
{% endhighlight %}

第一个构造器，通过指定数组的初始长度来构造ArrayList，对于参数initialCapacity的值：

* 若>0，则将elementData初始化为长度为initialCapacity的数组
* 若=0，则将elementData初始化为EMPTY_ELEMENTDATA
* 若<0，则抛出异常（数组的长度不可能为负）

第二个构造器，无参构造器，elementData被初始化为DEFAULTCAPACITY_EMPTY_ELEMENTDATA，当第一个元素被添加进ArrayList中时，被初始化为DEFAULTCAPACITY_EMPTY_ELEMENTDATA的elementData的长度会被扩充到DEFAULT_CAPACITY即10。

第三个构造器，接收一个Collection类型的对象，将elementData初始化为该Collection对象对应的数组，同时对其类型进行修正。

ArrayList是长度可变的动态数组，下面来看一下ArrayList的长度是如何动态变化的。

{% highlight bash linenos %}
/**
 * Appends the specified element to the end of this list.
 *
 * @param e element to be appended to this list
 * @return <tt>true</tt> (as specified by {@link Collection#add})
 */
public boolean add(E e) {
    ensureCapacityInternal(size + 1);  // Increments modCount!!
    elementData[size++] = e;
    return true;
}
{% endhighlight %}

通过调用ArrayList的add方法，我们可以将一个元素添加到ArrayList中，在该方法中，首先调用了ensureCapacityInternal方法，接下来将要添加的对象置于数组的末尾并将数组长度加一，最后返回true，那么显然，数组长度的动态改变便是在ensureCapacityInternal方法总完成的，该方法有一个名为minCapacity的整型参数，显然，这个参数的含义为容纳当前所有元素所需的最小容量，由于在add方法中我们需要添加一个元素，因此此时我们需要的最小容量为之前元素的个数size加一，因此传入的值为`size + 1`，跟进ensureCapacityInternal方法：

{% highlight bash linenos %}
private void ensureCapacityInternal(int minCapacity) {
    if (elementData == DEFAULTCAPACITY_EMPTY_ELEMENTDATA) {
        minCapacity = Math.max(DEFAULT_CAPACITY, minCapacity);
    }

    ensureExplicitCapacity(minCapacity);
}
{% endhighlight %}

在该方法中，首先对elementData进行判定，若是DEFAULTCAPACITY_EMPTY_ELEMENTDATA则将minCapacity置为minCapacity和DEFAULT_CAPACITY的最大值，只有在使用第二种构造器时，elementData会被初始化为DEFAULTCAPACITY_EMPTY_ELEMENTDATA，因此在使用第二种构造器的情况下，在第一个元素被添加到ArrayList的过程中，数组的长度会被扩展为10。接下来将minCapacity作为参数调用ensureExplicitCapacity方法，跟进ensureExplicitCapacity方法：

{% highlight bash linenos %}
private void ensureExplicitCapacity(int minCapacity) {
    modCount++;

    // overflow-conscious code
    if (minCapacity - elementData.length > 0)
        grow(minCapacity);
}
{% endhighlight %}

在该方法中，首先对modCount作了一次累加（这个字段的含义为ArrayLits被修改的次数），接下来对`minCapacity - elementData.length`的值进行判断，正值为真，否则为假，那么这个表达式的意义是什么呢？

* 表达式为真时，我们需要的最小容量比数组当前的长度要大，因此我们需要对数组进行扩充，即调用grow方法。
* 表达式为假时，我们需要的最小容量不大于当前数组的长度，即当前数组并不需要扩充，直接返回即可。

当需要对数组进行扩充时应以何种策略进行扩充呢？跟进grow方法：

{% highlight bash linenos %}
/**
 * Increases the capacity to ensure that it can hold at least the
 * number of elements specified by the minimum capacity argument.
 *
 * @param minCapacity the desired minimum capacity
 */
private void grow(int minCapacity) {
    // overflow-conscious code
    int oldCapacity = elementData.length;
    int newCapacity = oldCapacity + (oldCapacity >> 1);
    if (newCapacity - minCapacity < 0)
        newCapacity = minCapacity;
    if (newCapacity - MAX_ARRAY_SIZE > 0)
        newCapacity = hugeCapacity(minCapacity);
    // minCapacity is usually close to size, so this is a win:
    elementData = Arrays.copyOf(elementData, newCapacity);
}
{% endhighlight %}

在该方法中，我们需要找出一个适合ArrayList的新容量newCapacity，关于newCapacity有三点需要说明：

* __下界__，我们已经知道minCapacity是我们容纳所有元素所需的最小容量，因此这个值应该作为newCapacity的下界。
* __上界__，由于数组的下标为整型，因此数组的长度也应该为整型，所以将`Integer.MAX_VALUE`设置为newCapacity的上界。
* __初始值__，那么newCapacity的初始值应该如何设定呢？在这里ArrayList的开发者使用的策略是未扩充前的数组的长度的1.5倍（向下取整），那么这么做的好处是什么？接下来我们来探究一波

{% highlight bash linenos %}
public class GrowTest {

	private boolean needGrow;

	private int size;

	private int length;

	private void add() {
		ensureExplicitCapacity(size++ + 1);
	}

	private void ensureExplicitCapacity(int minCapacity) {
		if (minCapacity - length > 0)
			grow(minCapacity);
	}

	private void grow(int minCapacity) {
		needGrow = true;

		int oldCapacity = length;
		int newCapacity = oldCapacity + (oldCapacity >> 1);
		if (newCapacity - minCapacity < 0)
			newCapacity = minCapacity;
		length = newCapacity;
	}

	public GrowTest() {
		// column names
		print("add times");
		print("length of array");
		print("size of elements");
		print("need grow");
		System.out.println();

		// contents
		for (int i = 0; i < 100; i++) {
			needGrow = false;

			add();

			print((i + 1));
			print(length);
			print(size);
			print(needGrow ? "yes" : "");
			System.out.println();
		}
	}

	public static void main(String[] args) {
		new GrowTest();
	}

}

//运行结果
add times           length of array     size of elements    need grow           
#1                  1                   1                   yes                 
#2                  2                   2                   yes                 
#3                  3                   3                   yes                 
#4                  4                   4                   yes                 
#5                  6                   5                   yes                 
#6                  6                   6                                       
#7                  9                   7                   yes                 
#8                  9                   8                                       
#9                  9                   9                                       
#10                 13                  10                  yes                 
#11                 13                  11                                      
#12                 13                  12                                      
#13                 13                  13                                      
#14                 19                  14                  yes                 
#15                 19                  15                                      
#16                 19                  16                                      
#17                 19                  17                                      
#18                 19                  18                                      
#19                 19                  19                                      
#20                 28                  20                  yes                 
#21                 28                  21                                      
#22                 28                  22                                      
#23                 28                  23                                      
#24                 28                  24                                      
#25                 28                  25                                      
#26                 28                  26                                      
#27                 28                  27                                      
#28                 28                  28                                      
#29                 42                  29                  yes                 
#30                 42                  30                                      
#31                 42                  31                                      
#32                 42                  32                                      
#33                 42                  33                                      
#34                 42                  34                                      
#35                 42                  35                                      
#36                 42                  36                                      
#37                 42                  37                                      
#38                 42                  38                                      
#39                 42                  39                                      
#40                 42                  40                                      
#41                 42                  41                                      
#42                 42                  42                                      
#43                 63                  43                  yes                 
#44                 63                  44                                      
#45                 63                  45                                      
#46                 63                  46                                      
#47                 63                  47                                      
#48                 63                  48                                      
#49                 63                  49                                      
#50                 63                  50                                      
#51                 63                  51                                      
#52                 63                  52                                      
#53                 63                  53                                      
#54                 63                  54                                      
#55                 63                  55                                      
#56                 63                  56                                      
#57                 63                  57                                      
#58                 63                  58                                      
#59                 63                  59                                      
#60                 63                  60                                      
#61                 63                  61                                      
#62                 63                  62                                      
#63                 63                  63                                      
#64                 94                  64                  yes                 
#65                 94                  65                                      
#66                 94                  66                                      
#67                 94                  67                                      
#68                 94                  68                                      
#69                 94                  69                                      
#70                 94                  70                                      
#71                 94                  71                                      
#72                 94                  72                                      
#73                 94                  73                                      
#74                 94                  74                                      
#75                 94                  75                                      
#76                 94                  76                                      
#77                 94                  77                                      
#78                 94                  78                                      
#79                 94                  79                                      
#80                 94                  80                                      
#81                 94                  81                                      
#82                 94                  82                                      
#83                 94                  83                                      
#84                 94                  84                                      
#85                 94                  85                                      
#86                 94                  86                                      
#87                 94                  87                                      
#88                 94                  88                                      
#89                 94                  89                                      
#90                 94                  90                                      
#91                 94                  91                                      
#92                 94                  92                                      
#93                 94                  93                                      
#94                 94                  94                                      
#95                 141                 95                  yes                 
#96                 141                 96                                      
#97                 141                 97                                      
#98                 141                 98                                      
#99                 141                 99                                      
#100                141                 100                                     
{% endhighlight %}

在这一段程序中，我们模拟了ArrayList（通过第一种构造器构造的initialCapacity为0的ArrayList）中数组长度动态增加的一个过程，可以看到，通过使用这种策略，在我们不断向ArrayList中添加元素的过程中，需要扩充数组长度的grow操作的频率逐渐降低，这使得add操作的效率大大提高了，嗨呀。

__在不断调用add方法的过程中，需要的最小容量minCapacity以线性方式不断增长，而newCapacity在进行grow操作时是以接近指数增长的方式进行增长，增长后的newCapacity将作为数组的长度，一旦数组长度在数量上超过了minCapacity，那么在接下来的对add方法的调用过程中均不会进行grow操作直至minCapacity线性增长后超过数组长度，这时会对数组长度再次进行grow操作。但是，根据所学的关于线性函数和指数函数的知识，随着横坐标的不断增加，指数函数在纵坐标上的增幅会远大于线性函数，这也就意味着，随着我们添加到ArrayList中的元素的数量越来越多，数组每进行一次grow操作，minCapacity就会需要更多的add调用以使minCapacity在数量上达到数组长度，这也就进一步导致了grow操作被调用的频率不断降低。__

接下来看一下关于ArrayList的一些常规操作。

* 获取指定位置的元素，只需根据下标获取elementData数组中的相应元素即可，效率较高。

{% highlight bash linenos %}
@SuppressWarnings("unchecked")
E elementData(int index) {
    return (E) elementData[index];
}

/**
 * Returns the element at the specified position in this list.
 *
 * @param  index index of the element to return
 * @return the element at the specified position in this list
 * @throws IndexOutOfBoundsException {@inheritDoc}
 */
public E get(int index) {
    rangeCheck(index);

    return elementData(index);
}
{% endhighlight %}

* 在指定位置添加元素，在指定位置添加元素需要将下标后的所有元素均后移一位，因此效率较低。

{% highlight bash linenos %}
/**
 * Inserts the specified element at the specified position in this
 * list. Shifts the element currently at that position (if any) and
 * any subsequent elements to the right (adds one to their indices).
 *
 * @param index index at which the specified element is to be inserted
 * @param element element to be inserted
 * @throws IndexOutOfBoundsException {@inheritDoc}
 */
public void add(int index, E element) {
    rangeCheckForAdd(index);

    ensureCapacityInternal(size + 1);  // Increments modCount!!
    System.arraycopy(elementData, index, elementData, index + 1,
                     size - index);
    elementData[index] = element;
    size++;
}
{% endhighlight %}

* 删除指定位置/对象的元素，删除指定的元素需要将其后的所有元素均前移一位，因此效率较低。

{% highlight bash linenos %}
/**
 * Removes the element at the specified position in this list.
 * Shifts any subsequent elements to the left (subtracts one from their
 * indices).
 *
 * @param index the index of the element to be removed
 * @return the element that was removed from the list
 * @throws IndexOutOfBoundsException {@inheritDoc}
 */
public E remove(int index) {
    rangeCheck(index);

    modCount++;
    E oldValue = elementData(index);

    int numMoved = size - index - 1;
    if (numMoved > 0)
        System.arraycopy(elementData, index+1, elementData, index,
                         numMoved);
    elementData[--size] = null; // clear to let GC do its work

    return oldValue;
}

/**
 * Removes the first occurrence of the specified element from this list,
 * if it is present.  If the list does not contain the element, it is
 * unchanged.  More formally, removes the element with the lowest index
 * <tt>i</tt> such that
 * <tt>(o==null&nbsp;?&nbsp;get(i)==null&nbsp;:&nbsp;o.equals(get(i)))</tt>
 * (if such an element exists).  Returns <tt>true</tt> if this list
 * contained the specified element (or equivalently, if this list
 * changed as a result of the call).
 *
 * @param o element to be removed from this list, if present
 * @return <tt>true</tt> if this list contained the specified element
 */
public boolean remove(Object o) {
    if (o == null) {
        for (int index = 0; index < size; index++)
            if (elementData[index] == null) {
                fastRemove(index);
                return true;
            }
    } else {
        for (int index = 0; index < size; index++)
            if (o.equals(elementData[index])) {
                fastRemove(index);
                return true;
            }
    }
    return false;
}
{% endhighlight %}

__对ArrayList的总结：长度可变的动态数组，随机访问效率较高，而插入/删除操作的效率较低。__

#### __LinkedList__

LinkedList和ArrayList一样具有保存同种类型元素的功能，但是这里有一个很显著的区别，那就是ArrayList对元素的储存是通过数组来进行的，其动态的特性是通过改变数组的长度来进行的，而在LinkedList中则有所区别，在LinkedList中，储存的所有元素都被封装为一个Node类型的对象，Node类如下：

{% highlight bash linenos %}
private static class Node<E> {
    E item;
    Node<E> next;
    Node<E> prev;

    Node(Node<E> prev, E element, Node<E> next) {
        this.item = element;
        this.next = next;
        this.prev = prev;
    }
}
{% endhighlight %}

这个类和C++中的双向链表结点的结构非常相似，其中`E item`用于指向我们需要插入LinkedList中的对象，`Node<E> next`为后继结点，`Node<E> prev`为前驱结点，那么，很容易看出，LinkedList就是一个双向的链表。

LinkedList中有三个字段，分别是：

* size，即LinkedList中储存的元素的个数。
* first，LinkedList中的头结点，当LinkedList为空时first为空。
* last，LinkedList中的尾结点，当LinkedList为空时last为空。

LinkedList提供了两个构造器：

{% highlight bash linenos %}
/**
 * Constructs an empty list.
 */
public LinkedList() {
}

/**
 * Constructs a list containing the elements of the specified
 * collection, in the order they are returned by the collection's
 * iterator.
 *
 * @param  c the collection whose elements are to be placed into this list
 * @throws NullPointerException if the specified collection is null
 */
public LinkedList(Collection<? extends E> c) {
    this();
    addAll(c);
}
{% endhighlight %}

第一个构造器是无参的空构造器，由于LinkedList是一个链表结构，因此并不需要做什么初始化工作。

第二个构造器接收一个Collection类型的对象，并调用了addAll方法将Collection中的所有元素加入到LinkedList中，addAll方法稍后再做介绍。

下面来介绍LinkedList中的一些主要方法。

__linkFirst和linkLast__
{% highlight bash linenos %}
/**
 * Links e as first element.
 */
private void linkFirst(E e) {
    final Node<E> f = first;
    final Node<E> newNode = new Node<>(null, e, f);
    first = newNode;
    if (f == null)
        last = newNode;
    else
        f.prev = newNode;
    size++;
    modCount++;
}

/**
 * Links e as last element.
 */
void linkLast(E e) {
    final Node<E> l = last;
    final Node<E> newNode = new Node<>(l, e, null);
    last = newNode;
    if (l == null)
        first = newNode;
    else
        l.next = newNode;
    size++;
    modCount++;
}
{% endhighlight %}

linkFirst方法的作用是将一个元素插入到双向链表的头部作为新的头结点，由于头结点的前驱结点为空，因此使用null和first作为新添加元素的前驱和后继元素来构造Node，然后我们将first赋值为新添加的元素，同时判断之前的链表是否为空，若为空，则将last也赋值为新添加的元素，若不为空，则修改之前的first结点的前驱结点使其指向我们新添加的元素，最后将size和modCount（修改次数）分别作加一操作。linkLast方法的作用是将一个元素插入到双向链表的尾部作为新的尾结点，原理同linkFirst类似。

__linkBefore__
{% highlight bash linenos %}
/**
 * Inserts element e before non-null Node succ.
 */
void linkBefore(E e, Node<E> succ) {
    // assert succ != null;
    final Node<E> pred = succ.prev;
    final Node<E> newNode = new Node<>(pred, e, succ);
    succ.prev = newNode;
    if (pred == null)
        first = newNode;
    else
        pred.next = newNode;
    size++;
    modCount++;
}
{% endhighlight %}

linkBefore方法的作用是在一个指定的非空结点前插入一个元素，易知，新插入元素的前驱和后继结点即succ.prev和succ，那么以此来构造Node对象即可，同时将succ的前驱结点修改为指向新插入的结点，之后，判断succ.prev是否为空，若为空说明插入钱succ为头结点，那么我们需要将first赋值为新插入的元素，若不为空则将succ.prev的后继结点修改为指向新插入的结点，最后将size和modCount分别作加一操作。

__unlinkFirst和unlinkLast__
{% highlight bash linenos %}
/**
 * Unlinks non-null first node f.
 */
private E unlinkFirst(Node<E> f) {
    // assert f == first && f != null;
    final E element = f.item;
    final Node<E> next = f.next;
    f.item = null;
    f.next = null; // help GC
    first = next;
    if (next == null)
        last = null;
    else
        next.prev = null;
    size--;
    modCount++;
    return element;
}

/**
 * Unlinks non-null last node l.
 */
private E unlinkLast(Node<E> l) {
    // assert l == last && l != null;
    final E element = l.item;
    final Node<E> prev = l.prev;
    l.item = null;
    l.prev = null; // help GC
    last = prev;
    if (prev == null)
        first = null;
    else
        prev.next = null;
    size--;
    modCount++;
    return element;
}
{% endhighlight %}

unlinkFirst方法的作用是将链表中的头结点从链表中删除，易知，将头结点删除后，first.next将成为新的头结点。首先，我们需要将原头结点中的元素引用以及对后继结点的引用置为空（头结点的前驱结点已经为空了不需要我们显式地置为空），这么做是为了方便进行gc，接下来将first赋值为first.next，然后需要判断first是否为空，若为空，则说明链表已不包含任何元素，则直接将last也置为空，若不为空，则只需将first的前驱结点置为空即可，最后将size减一，modCount加一。unlinkLast方法的作用是将链表中的尾结点从链表中删除，原理同unlinkFirst类似。

__unlink__
{% highlight bash linenos %}
/**
 * Unlinks non-null node x.
 */
E unlink(Node<E> x) {
    // assert x != null;
    final E element = x.item;
    final Node<E> next = x.next;
    final Node<E> prev = x.prev;

    if (prev == null) {
        first = next;
    } else {
        prev.next = next;
        x.prev = null;
    }

    if (next == null) {
        last = prev;
    } else {
        next.prev = prev;
        x.next = null;
    }

    x.item = null;
    size--;
    modCount++;
    return element;
}
{% endhighlight %}

unlink方法的作用是将一个非空结点从链表中删除，那么基本的操作就是将其前驱结点的后继结点指向其后继结点，将其后继结点的前驱结点指向其前驱结点。同时需要对是否为头/尾结点进行相应的判定，并进行相应的操作，以及将需要删除的结点的前驱和后继结点的引用和对元素的引用置空。最后将size减一，modCount加一。

__addAll方法__
{% highlight bash linenos %}
/**
 * Inserts all of the elements in the specified collection into this
 * list, starting at the specified position.  Shifts the element
 * currently at that position (if any) and any subsequent elements to
 * the right (increases their indices).  The new elements will appear
 * in the list in the order that they are returned by the
 * specified collection's iterator.
 *
 * @param index index at which to insert the first element
 *              from the specified collection
 * @param c collection containing elements to be added to this list
 * @return {@code true} if this list changed as a result of the call
 * @throws IndexOutOfBoundsException {@inheritDoc}
 * @throws NullPointerException if the specified collection is null
 */
public boolean addAll(int index, Collection<? extends E> c) {
    checkPositionIndex(index);

    Object[] a = c.toArray();
    int numNew = a.length;
    if (numNew == 0)
        return false;

    Node<E> pred, succ;
    if (index == size) {
        succ = null;
        pred = last;
    } else {
        succ = node(index);
        pred = succ.prev;
    }

    for (Object o : a) {
        @SuppressWarnings("unchecked") E e = (E) o;
        Node<E> newNode = new Node<>(pred, e, null);
        if (pred == null)
            first = newNode;
        else
            pred.next = newNode;
        pred = newNode;
    }

    if (succ == null) {
        last = pred;
    } else {
        pred.next = succ;
        succ.prev = pred;
    }

    size += numNew;
    modCount++;
    return true;
}
{% endhighlight %}

addAll方法的作用是将一个Collection对象中包含的所有元素加入到LinkedList的指定位置，首先对index进行判断，如果`index == size`为真，则说明我们是在将一组元素加入到链表尾部，此时我们将pred置为last，将succ置为空，如果为假，则说明我们是在将一组元素加入到链表的中间，则将succ置为index对应的元素，将pred置为succ的前驱结点，那么显然，prev即是需要加入的一组元素的第一个元素的前驱，succ即是需要加入的一组元素的最后一个元素的后继。接下来对需要添加的元素进行遍历，并依次为每个结点设置前驱和后继，由于每个结点的后继结点是在结点被创建的下一轮迭代中设置的，因此跳出循环后我们需要为添加的最后一个元素设置后继结点，若succ为空说明最后一个添加的元素即为尾结点，否则将最后一个元素的后继设置为succ同时将succ的前驱设置为pred即可。最后，修改size和modCount。

__node__
{% highlight bash linenos %}
/**
 * Returns the (non-null) Node at the specified element index.
 */
Node<E> node(int index) {
    // assert isElementIndex(index);

    if (index < (size >> 1)) {
        Node<E> x = first;
        for (int i = 0; i < index; i++)
            x = x.next;
        return x;
    } else {
        Node<E> x = last;
        for (int i = size - 1; i > index; i--)
            x = x.prev;
        return x;
    }
}
{% endhighlight %}

node方法的主要作用是根据index获取链表中相应位置的结点，逻辑很简单，首先通过一个简单的二分法判断index是处于size的前半部分还是后半部分，处于前半部分则从头结点开始遍历，处于后半部分则从尾结点进行遍历。

__indexOf__
{% highlight bash linenos %}
/**
 * Returns the index of the first occurrence of the specified element
 * in this list, or -1 if this list does not contain the element.
 * More formally, returns the lowest index {@code i} such that
 * <tt>(o==null&nbsp;?&nbsp;get(i)==null&nbsp;:&nbsp;o.equals(get(i)))</tt>,
 * or -1 if there is no such index.
 *
 * @param o element to search for
 * @return the index of the first occurrence of the specified element in
 *         this list, or -1 if this list does not contain the element
 */
public int indexOf(Object o) {
    int index = 0;
    if (o == null) {
        for (Node<E> x = first; x != null; x = x.next) {
            if (x.item == null)
                return index;
            index++;
        }
    } else {
        for (Node<E> x = first; x != null; x = x.next) {
            if (o.equals(x.item))
                return index;
            index++;
        }
    }
    return -1;
}
{% endhighlight %}

indexOf方法的主要作用是获取元素在链表中的位置，这是通过遍历链表判断对象是否equal来实现的。

__那么，很容易看出，LinkedList中的大部分操作都是对上述的方法进行了一些简单的封装来实现的，对LinkedList的总结：随机访问要通过遍历链表来实现，相比于ArrayList效率较低，插入/删除操作只需从链表中获取到相应位置的结点然后调整相关前驱后继结点即可而非像ArrayList中需要对数组进行复制移动等操作，因此插入/删除操纵效率较高。__





































































































































































