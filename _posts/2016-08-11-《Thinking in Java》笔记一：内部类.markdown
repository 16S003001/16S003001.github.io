---
layout: post
title: "《Thinking in Java》笔记一：内部类"
author: Guomato
date: 2016-08-11 16:27:06 +0800
categories: [Java, 《Thinking in Java》笔记]
---

## __非静态内部类__

非静态内部类通常具有如下的形式：

{% highlight ruby linenos %}
class Outer {
	
    public Outer() {}

    class Inner {
		
        public Inner() {}

    }

}
{% endhighlight %}

非静态内部类可以访问其外部类的所有字段和方法，这是由于非静态内部类在被创建的时候会隐式地创建一个指向其外部类对象的引用，对外部类中的字段和方法的访问均是通过这个引用来进行的。那么，内部类对象存在的一个必要条件就是：必须存在相应的外部类对象。

同时，我们可以由此必要条件了解到创建内部类对象的方法，首先我们必须创建一个外部类对象，然后通过此外部类对象来创建内部类对象。在下面的例子中，Inner和PrivateInner是Outer的两个内部类，区别在于，第一个内部类的可见性是包可见性，而第二个内部类的可见性是私有的。在main方法中，我们首先创建了一个外部类Outer对象，然后通过此对象我们可以创建Inner对象，但是我们无法创建PrivateInner对象，这是因为其可见性为private使得我们无法访问到类名从而无法创建对象，可见性为private的内部类只能在外部类的内部使用。

{% highlight ruby linenos %}
public class Test {
	
	public static void main(String[] args) {
		Outer outer = new Outer();
		
		Outer.Inner inner = outer.new Inner();
		//Outer.PrivateInner privateInner = outer.new PrivateInner();
	}
	
}

class Outer {
	
	public Outer() {
		System.out.println("Outer initialized");
	}
	
	class Inner {
		
		public Inner() {
			System.out.println("Inner initialized");
		}
		
	}
	
	private class PrivateInner {
		
		public PrivateInner() {
			System.out.println("PrivateInner initialized");
		}
		
	}
	
}
{% endhighlight %}

__在使用非静态内部类时需要注意有可能会发生内存泄漏__，下面通过一些例子来说明。

#### __例子：内部类对象以普通成员变量方式被引用__

{% highlight ruby linenos %}
class Outer {
	
	private Inner inner;
	
	public Outer() {
		System.out.println("Outer initialized");
	}
	
	@Override
	protected void finalize() throws Throwable {
		System.out.println("Outer finalized");
		
		super.finalize();
	}
	
	class Inner {
		
		public Inner() {
			System.out.println("Inner initialized");
		}
		
		@Override
		protected void finalize() throws Throwable ｛
			System.out.println("Inner finalized");
		
			super.finalize();
		}
		
	}
	
	public static void main(String[] args) {
		Outer outer = new Outer();
		outer.inner = outer.new Inner();
		
		outer = null;
		
		System.gc();
	}
	
}

//运行结果
Outer initialized
Inner initialized
Inner finalized
Outer finalized
{% endhighlight %}

在这个例子中，Outer为外部类，Inner为内部类，在main方法中，我们依次创建了Outer和Inner对象，并将Outer对象中的成员变量inner指向我们创建的Inner对象，由于Inner是内部类，因此在Inner对象被创建时，会隐式地创建一个指向其外部类对象的引用。那么现在，Outer对象与Inner对象上的引用关系便如下图所示：

![非静态内部类作为普通成员变量被引用的引用关系图](https://ooo.0o0.ooo/2016/08/11/57ac97f91c6d2.png)

在35行，我们将outer变量即来自堆栈的引用置为null，那么，来自堆栈的引用不见了，两个对象便变成了下图所示的循环引用关系，在Java内存回收机制中，这样的对象被认为是不可达的，因此当我们调用`System.gc()`时，两个对象都会被正常回收，正如我们的运行结果所示。

![非静态内部类作为普通成员变量被引用的引用关系图（gc后）](https://ooo.0o0.ooo/2016/08/11/57ac98003c25e.png)

#### __例子：内部类对象以静态成员变量方式被引用__

首先需要说明，static静态变量或方法均存储于内存的方法区，其生命周期与整个程序的生命周期相同。

{% highlight ruby linenos %}
class Outer {
	
	private static Inner inner;

	...
	
}

//运行结果
Outer initialized
Inner initialized
{% endhighlight %}

在这里只需对上面的代码进行一些改动，将上一段代码中的Inner类型的普通成员变量改为静态成员变量。由于inner变量为static类型，因此当它被创建时会被存储在方法区，并获得和程序一样长的生命周期，相应的引用关系如下图所示：

![非静态内部类作为静态成员变量被引用的引用关系图](https://ooo.0o0.ooo/2016/08/11/57ac9ad60b74a.png)

那么当我们将outer变量即来自堆栈的引用置为null，并调用`System.gc()`后，引用关系如下图所示，由于gc只清理堆中的内存，方法区中的静态变量并不会被清理，因此此时Inner对象是可达的，同时由于Inner类是Outer类的内部类，因此Inner对象持有Outer对象的引用，这便导致了Outer对象也是可达的，因此无法被gc回收，正如我们的运行结果所示，__此时发生了我们不再需要Outer对象但Outer对象无法被回收的情况，即发生了内存泄漏__。

![非静态内部类作为静态成员变量被引用的引用关系图（gc后）](https://ooo.0o0.ooo/2016/08/11/57ac9ad054cdf.png)





























