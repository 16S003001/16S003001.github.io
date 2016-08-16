---
layout: post
title: "《Thinking in Java》笔记一：内部类"
author: Guomato
date: 2016-08-11 16:27:06 +0800
categories: [Java, 《Thinking in Java》笔记]
---

## __非静态内部类__

非静态内部类通常具有如下的形式：

{% highlight bash linenos %}
class Outer {
	
    public Outer() {}

    class Inner {
		
        public Inner() {}

    }

}
{% endhighlight %}

非静态内部类可以访问其外部类的所有字段和方法，这是由于非静态内部类在被创建的时候会隐式地创建一个指向其外部类对象的引用，对外部类中的字段和方法的访问均是通过这个引用来进行的。那么，内部类对象存在的一个必要条件就是：必须存在相应的外部类对象。

同时，我们可以由此必要条件了解到创建内部类对象的方法，首先我们必须创建一个外部类对象，然后通过此外部类对象来创建内部类对象。在下面的例子中，Inner和PrivateInner是Outer的两个内部类，区别在于，第一个内部类的可见性是包可见性，而第二个内部类的可见性是私有的。在main方法中，我们首先创建了一个外部类Outer对象，然后通过此对象我们可以创建Inner对象，但是我们无法创建PrivateInner对象，这是因为其可见性为private使得我们无法访问到类名从而无法创建对象，可见性为private的内部类只能在外部类的内部使用。

{% highlight bash linenos %}
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

{% highlight bash linenos %}
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

{% highlight bash linenos %}
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

## __静态内部类__

{% highlight bash linenos %}
public class Outer {

	public Outer() {
		System.out.println("Outer initialized");
	}
	
	private void hello() {
		System.out.println("hello");
	}
	
	private static void staticHello() {
		System.out.println("static hello");
	}
	
	static class StaticInner {
		
		private static int sCounter = 0;

		public StaticInner() {
			System.out.println("StaticInner");
			
			//hello();
			staticHello();
		}
		
	}
	
	public static void main(String[] args) {
		StaticInner staticInner = new StaticInner();
	}
	
}
{% endhighlight %}

关于静态内部类（《Thinking in Java》中称作嵌套类），在第201页有如下两点描述：

* 要创建嵌套类的对象，并不需要其外围类的对象
* 不能从嵌套类的对象中访问非静态的非静态的外围类对象

我们知道，非静态内部类对象的创建必须依赖于其外部类对象的存在性，而静态内部类却不具有这种特征，那么同样，静态内部类的对象也不会持有外部类对象的引用，因此无法访问外部类对象中非静态的成员变量和方法。静态内部类和非静态内部类还有一点区别就是非静态内部类中无法定义静态变量和方法，而在静态内部类中是可以的（关于这一点的原因有待补充）。

在这里说明一点，非静态内部类对象以静态成员变量方式被外部类对象引用时可能会发生内存泄漏，而当内部类为静态内部类时上面描述的内存泄漏现象便不会发生，这是由于静态内部类对象并不会隐式地创建任何外部类对象的引用。

## __匿名内部类和局部内部类__

{% highlight bash linenos %}
public class Outer {

	public Outer() {
		System.out.println("Outer initialized");
	}

	private I1 localInnerClass(String localName) {
		class LocalInnerClass implements I1 {

			private String name;
			
			public LocalInnerClass(String name) {
				System.out.println("Local inner class initialized");
				
				this.name = name;
			}
			
			@Override
			public void hello() {
				System.out.println("Hello " + name);
			}
			
		}
		return new LocalInnerClass(localName);
	}
	
	private I1 anonymousInnerClass(final String anonymousName) {
		return new I1() {

			private String name;
			
			{
				System.out.println("Anonymous inner class");
				
				this.name = anonymousName;
			}
			
			@Override
			public void hello() {
				System.out.println("Hello " + name);
			}
		};
	}
	
	public static void main(String[] args) {
		Outer outer = new Outer();

		outer.localInnerClass("Local innner class").hello();
		outer.anonymousInnerClass("Anonymous innner class").hello();
	}
	
}

interface I1 {
	
	void hello();
	
}

//运行结果
Outer initialized
Local inner class initialized
Hello Local innner class
Anonymous inner class initialized
Hello Anonymous innner classc
{% endhighlight %}

局部内部类是定义在方法或是代码块中的内部类，由于在方法或代码块外该类是不可见的，因此不能为该类添加访问权限修饰符，但该内部类对于外部类中的所有成员变量及方法是具有访问权限的，同时，如果有需要，在局部内部类中可以对构造方法进行重载。

匿名内部类可以用来继承类或是实现接口，但只能是其中之一，同样地在方法或代码块外是不可见的，匿名内部类对于外部类的所有成员变量及方法是具有访问权限的，需要注意的是位于匿名类定义所在的方法或代码块内部的变量，若匿名类需要访问该变量则需要为该变量加上final修饰符。由于匿名内部类不具有名字，因此无法在匿名内部类中重载构造方法，只能使用默认的构造方法，要想实现类似构造方法的效果，可以通过在匿名内部类中添加实例初始化代码块来实现。

匿名内部类和局部内部类具有相似的功能，不过需要注意的是以下两种情况发生时，局部内部类将成为我们更好的选择：

* 需要对构造方法进行重载时，显而易见，这是由于匿名内部类中无法对构造方法进行重载。
* 需要多个内部类的对象时，若使用局部内部类，我们只需通过多次`new LocalInnerClass()`便可创建多个内部类的对象，若使用匿名内部类，每当我们需要创建一个内部类的实例时都需要重新给出匿名内部类的定义，这显然是不合适的。






















