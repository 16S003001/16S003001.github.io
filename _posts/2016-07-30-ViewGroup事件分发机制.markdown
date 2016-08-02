---
layout: post
title: "ViewGroup事件分发机制"
author: Guomato
date: 2016-07-30 17:30:26 +0800
categories: [Android源码]
---
继上一篇[View事件分发机制](http://guomato.github.io/android/view/2016/07/24/View事件分发机制.html)后，本篇博客将会分析ViewGroup的事件分发机制。

在自定义了继承自View的组件CustomButton后，本篇需添加继承自ViewGroup的自定义组件CustomLinearLayout并重写相关方法，布局文件及自定义组件如下：

CustomLinearLayout.java
{% highlight ruby linenos %}
public class CustomLinearLayout extends LinearLayout {

    private static final String TAG = CustomLinearLayout.class.getSimpleName();

    public CustomLinearLayout(Context context) {
        super(context);
    }

    public CustomLinearLayout(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public CustomLinearLayout(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @Override
    public boolean dispatchTouchEvent(MotionEvent ev) {
        switch (ev.getAction()) {
            case MotionEvent.ACTION_DOWN:
                Log.d(TAG, "dispatchTouchEvent ACTION_DOWN");
                break;
            case MotionEvent.ACTION_MOVE:
                Log.d(TAG, "dispatchTouchEvent ACTION_MOVE");
                break;
            case MotionEvent.ACTION_UP:
                Log.d(TAG, "dispatchTouchEvent ACTION_UP");
                break;
        }
        return super.dispatchTouchEvent(ev);
    }

    @Override
    public boolean onInterceptTouchEvent(MotionEvent ev) {
        switch (ev.getAction()) {
            case MotionEvent.ACTION_DOWN:
                Log.d(TAG, "onInterceptTouchEvent ACTION_DOWN");
                break;
            case MotionEvent.ACTION_MOVE:
                Log.d(TAG, "onInterceptTouchEvent ACTION_MOVE");
                break;
            case MotionEvent.ACTION_UP:
                Log.d(TAG, "onInterceptTouchEvent ACTION_UP");
                break;
        }
        return super.onInterceptTouchEvent(ev);
    }

    @Override
    public boolean onTouchEvent(MotionEvent ev) {
        switch (ev.getAction()) {
            case MotionEvent.ACTION_DOWN:
                Log.d(TAG, "onTouchEvent ACTION_DOWN");
                break;
            case MotionEvent.ACTION_MOVE:
                Log.d(TAG, "onTouchEvent ACTION_MOVE");
                break;
            case MotionEvent.ACTION_UP:
                Log.d(TAG, "onTouchEvent ACTION_UP");
                break;
        }
        return super.onTouchEvent(ev);
    }
}
{% endhighlight %}

activity_main.xml
{% highlight ruby linenos %}
<com.guoyonghui.eventdispatch.view.CustomLinearLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:gravity="center"
    android:orientation="vertical"
    android:paddingBottom="@dimen/activity_vertical_margin"
    android:paddingLeft="@dimen/activity_horizontal_margin"
    android:paddingRight="@dimen/activity_horizontal_margin"
    android:paddingTop="@dimen/activity_vertical_margin"
    tools:context="com.guoyonghui.eventdispatch.MainActivity">

    <com.guoyonghui.eventdispatch.view.CustomButton
        android:id="@+id/click"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:longClickable="true"
        android:text="@string/app_name"
        android:textAllCaps="false"/>

</com.guoyonghui.eventdispatch.view.CustomLinearLayout>
{% endhighlight %}

单击自定义按钮后的控制台输出
{% highlight ruby linenos %}
07-30 22:00:28.037 4688-4688/com.guoyonghui.eventdispatch D/CustomLinearLayout: dispatchTouchEvent ACTION_DOWN
07-30 22:00:28.037 4688-4688/com.guoyonghui.eventdispatch D/CustomLinearLayout: onInterceptTouchEvent ACTION_DOWN
07-30 22:00:28.037 4688-4688/com.guoyonghui.eventdispatch D/CustomButton: dispatchTouchEvent ACTION_DOWN
07-30 22:00:28.037 4688-4688/com.guoyonghui.eventdispatch D/CustomActivity: onTouch ACTION_DOWN
07-30 22:00:28.037 4688-4688/com.guoyonghui.eventdispatch D/CustomButton: onTouchEvent ACTION_DOWN
07-30 22:00:28.057 4688-4688/com.guoyonghui.eventdispatch D/CustomLinearLayout: dispatchTouchEvent ACTION_MOVE
07-30 22:00:28.057 4688-4688/com.guoyonghui.eventdispatch D/CustomLinearLayout: onInterceptTouchEvent ACTION_MOVE
07-30 22:00:28.057 4688-4688/com.guoyonghui.eventdispatch D/CustomButton: dispatchTouchEvent ACTION_MOVE
07-30 22:00:28.057 4688-4688/com.guoyonghui.eventdispatch D/CustomActivity: onTouch ACTION_MOVE
07-30 22:00:28.057 4688-4688/com.guoyonghui.eventdispatch D/CustomButton: onTouchEvent ACTION_MOVE
07-30 22:00:28.057 4688-4688/com.guoyonghui.eventdispatch D/CustomLinearLayout: dispatchTouchEvent ACTION_UP
07-30 22:00:28.057 4688-4688/com.guoyonghui.eventdispatch D/CustomLinearLayout: onInterceptTouchEvent ACTION_UP
07-30 22:00:28.057 4688-4688/com.guoyonghui.eventdispatch D/CustomButton: dispatchTouchEvent ACTION_UP
07-30 22:00:28.057 4688-4688/com.guoyonghui.eventdispatch D/CustomActivity: onTouch ACTION_UP
07-30 22:00:28.057 4688-4688/com.guoyonghui.eventdispatch D/CustomButton: onTouchEvent ACTION_UP
07-30 22:00:28.067 4688-4688/com.guoyonghui.eventdispatch D/CustomActivity: onClick
{% endhighlight %}

自定义View处于自定义ViewGroup中，从控制台输出中可以看出，事件分发相关方法的调用顺序为：ViewGroup dispatchTouchEvent -> ViewGroup onInterceptTouchEvent -> View dispatchTouchEvent -> View OnTouchListener -> View onTouchEvent -> View OnClickListener/OnLongClickListener

从View dispatchTouchEvent开始的部分在上一篇博客中已经进行了相关阐述，现在主要对ViewGroup dispatchTouchEvent -> ViewGroup onInterceptTouchEvent这一过程进行分析。

首先我们对ViewGroup.java中的dispatchTouchEvent方法进行一波OB，代码较长，先贴出来。

{% highlight ruby linenos %}
@Override
public boolean dispatchTouchEvent(MotionEvent ev) {
    if (mInputEventConsistencyVerifier != null) {
        mInputEventConsistencyVerifier.onTouchEvent(ev, 1);
    }

    // If the event targets the accessibility focused view and this is it, start
    // normal event dispatch. Maybe a descendant is what will handle the click.
    if (ev.isTargetAccessibilityFocus() && isAccessibilityFocusedViewOrHost()) {
        ev.setTargetAccessibilityFocus(false);
    }

    boolean handled = false;
    if (onFilterTouchEventForSecurity(ev)) {
        final int action = ev.getAction();
        final int actionMasked = action & MotionEvent.ACTION_MASK;

        // Handle an initial down.
        if (actionMasked == MotionEvent.ACTION_DOWN) {
            // Throw away all previous state when starting a new touch gesture.
            // The framework may have dropped the up or cancel event for the previous gesture
            // due to an app switch, ANR, or some other state change.
            cancelAndClearTouchTargets(ev);
            resetTouchState();
        }

        // Check for interception.
        final boolean intercepted;
        if (actionMasked == MotionEvent.ACTION_DOWN
                || mFirstTouchTarget != null) {
            final boolean disallowIntercept = (mGroupFlags & FLAG_DISALLOW_INTERCEPT) != 0;
            if (!disallowIntercept) {
                intercepted = onInterceptTouchEvent(ev);
                ev.setAction(action); // restore action in case it was changed
            } else {
                intercepted = false;
            }
        } else {
            // There are no touch targets and this action is not an initial down
            // so this view group continues to intercept touches.
            intercepted = true;
        }

        // If intercepted, start normal event dispatch. Also if there is already
        // a view that is handling the gesture, do normal event dispatch.
        if (intercepted || mFirstTouchTarget != null) {
            ev.setTargetAccessibilityFocus(false);
        }

        // Check for cancelation.
        final boolean canceled = resetCancelNextUpFlag(this)
                || actionMasked == MotionEvent.ACTION_CANCEL;

        // Update list of touch targets for pointer down, if needed.
        final boolean split = (mGroupFlags & FLAG_SPLIT_MOTION_EVENTS) != 0;
        TouchTarget newTouchTarget = null;
        boolean alreadyDispatchedToNewTouchTarget = false;
        if (!canceled && !intercepted) {

            // If the event is targeting accessiiblity focus we give it to the
            // view that has accessibility focus and if it does not handle it
            // we clear the flag and dispatch the event to all children as usual.
            // We are looking up the accessibility focused host to avoid keeping
            // state since these events are very rare.
            View childWithAccessibilityFocus = ev.isTargetAccessibilityFocus()
                    ? findChildWithAccessibilityFocus() : null;

            if (actionMasked == MotionEvent.ACTION_DOWN
                    || (split && actionMasked == MotionEvent.ACTION_POINTER_DOWN)
                    || actionMasked == MotionEvent.ACTION_HOVER_MOVE) {
                final int actionIndex = ev.getActionIndex(); // always 0 for down
                final int idBitsToAssign = split ? 1 << ev.getPointerId(actionIndex)
                        : TouchTarget.ALL_POINTER_IDS;

                // Clean up earlier touch targets for this pointer id in case they
                // have become out of sync.
                removePointersFromTouchTargets(idBitsToAssign);

                final int childrenCount = mChildrenCount;
                if (newTouchTarget == null && childrenCount != 0) {
                    final float x = ev.getX(actionIndex);
                    final float y = ev.getY(actionIndex);
                    // Find a child that can receive the event.
                    // Scan children from front to back.
                    final ArrayList<View> preorderedList = buildOrderedChildList();
                    final boolean customOrder = preorderedList == null
                            && isChildrenDrawingOrderEnabled();
                    final View[] children = mChildren;
                    for (int i = childrenCount - 1; i >= 0; i--) {
                        final int childIndex = customOrder
                                ? getChildDrawingOrder(childrenCount, i) : i;
                        final View child = (preorderedList == null)
                                ? children[childIndex] : preorderedList.get(childIndex);

                        // If there is a view that has accessibility focus we want it
                        // to get the event first and if not handled we will perform a
                        // normal dispatch. We may do a double iteration but this is
                        // safer given the timeframe.
                        if (childWithAccessibilityFocus != null) {
                            if (childWithAccessibilityFocus != child) {
                                continue;
                            }
                            childWithAccessibilityFocus = null;
                            i = childrenCount - 1;
                        }

                        if (!canViewReceivePointerEvents(child)
                                || !isTransformedTouchPointInView(x, y, child, null)) {
                            ev.setTargetAccessibilityFocus(false);
                            continue;
                        }

                        newTouchTarget = getTouchTarget(child);
                        if (newTouchTarget != null) {
                            // Child is already receiving touch within its bounds.
                            // Give it the new pointer in addition to the ones it is handling.
                            newTouchTarget.pointerIdBits |= idBitsToAssign;
                            break;
                        }

                        resetCancelNextUpFlag(child);
                        if (dispatchTransformedTouchEvent(ev, false, child, idBitsToAssign)) {
                            // Child wants to receive touch within its bounds.
                            mLastTouchDownTime = ev.getDownTime();
                            if (preorderedList != null) {
                                // childIndex points into presorted list, find original index
                                for (int j = 0; j < childrenCount; j++) {
                                    if (children[childIndex] == mChildren[j]) {
                                        mLastTouchDownIndex = j;
                                        break;
                                    }
                                }
                            } else {
                                mLastTouchDownIndex = childIndex;
                            }
                            mLastTouchDownX = ev.getX();
                            mLastTouchDownY = ev.getY();
                            newTouchTarget = addTouchTarget(child, idBitsToAssign);
                            alreadyDispatchedToNewTouchTarget = true;
                            break;
                        }

                        // The accessibility focus didn't handle the event, so clear
                        // the flag and do a normal dispatch to all children.
                        ev.setTargetAccessibilityFocus(false);
                    }
                    if (preorderedList != null) preorderedList.clear();
                }

                if (newTouchTarget == null && mFirstTouchTarget != null) {
                    // Did not find a child to receive the event.
                    // Assign the pointer to the least recently added target.
                    newTouchTarget = mFirstTouchTarget;
                    while (newTouchTarget.next != null) {
                        newTouchTarget = newTouchTarget.next;
                    }
                    newTouchTarget.pointerIdBits |= idBitsToAssign;
                }
            }
        }

        // Dispatch to touch targets.
        if (mFirstTouchTarget == null) {
            // No touch targets so treat this as an ordinary view.
            handled = dispatchTransformedTouchEvent(ev, canceled, null,
                    TouchTarget.ALL_POINTER_IDS);
        } else {
            // Dispatch to touch targets, excluding the new touch target if we already
            // dispatched to it.  Cancel touch targets if necessary.
            TouchTarget predecessor = null;
            TouchTarget target = mFirstTouchTarget;
            while (target != null) {
                final TouchTarget next = target.next;
                if (alreadyDispatchedToNewTouchTarget && target == newTouchTarget) {
                    handled = true;
                } else {
                    final boolean cancelChild = resetCancelNextUpFlag(target.child)
                            || intercepted;
                    if (dispatchTransformedTouchEvent(ev, cancelChild,
                            target.child, target.pointerIdBits)) {
                        handled = true;
                    }
                    if (cancelChild) {
                        if (predecessor == null) {
                            mFirstTouchTarget = next;
                        } else {
                            predecessor.next = next;
                        }
                        target.recycle();
                        target = next;
                        continue;
                    }
                }
                predecessor = target;
                target = next;
            }
        }

        // Update list of touch targets for pointer up or cancel, if needed.
        if (canceled
                || actionMasked == MotionEvent.ACTION_UP
                || actionMasked == MotionEvent.ACTION_HOVER_MOVE) {
            resetTouchState();
        } else if (split && actionMasked == MotionEvent.ACTION_POINTER_UP) {
            final int actionIndex = ev.getActionIndex();
            final int idBitsToRemove = 1 << ev.getPointerId(actionIndex);
            removePointersFromTouchTargets(idBitsToRemove);
        }
    }

    if (!handled && mInputEventConsistencyVerifier != null) {
        mInputEventConsistencyVerifier.onUnhandledEvent(ev, 1);
    }
    return handled;
}
{% endhighlight %}

{% highlight ruby linenos %}
public boolean onInterceptTouchEvent(MotionEvent ev) {
    return false;
}
{% endhighlight %}

如果不进行重写，ViewGroup中的onInterceptTouchEvent很简单，直接返回false，对任何事件都是拦截失败相当于不做拦截。

## ***在不拦截任何事件以及具有可接收事件的子视图的情况下***

#### ***首先讨论ACTION_DOWN事件***

用户一系列触控事件的开始是ACTION_DOWN事件，在第19-25行进行了ACTION_DOWN事件的一些初始化工作，这里涉及到一个叫做TouchTarget的类，从类名中我们可以大致看出，这是一个事件分发的目标类，而通过观察该类中的字段不难得知该类类似于一个链表，从表头到表尾的节点会依次接收事件分发，类中的child字段用于保存对应的子视图，next字段用于保存下一节点。通过调用cancelAndClearTouchTargets和resetTouchState方法可知，这几行代码的主要工作如下：

* 将链表重置并将表头mFirstTouchTarget置为空。
* 取消mGroupFlags的FLAG_DISALLOW_INTERCEPT标志，允许进行拦截。

接下来看到29-42行，此时mFirstTouchTarget已经被我们置为空，但由于此时事件为ACTION_DOWN因此，进入if代码块，易知disallowIntercept字段为false，所以此时会调用onInterceptTouchEvent方法，由于现在我们并未重写该方法即未做任何拦截，因此intercepted字段将被置为false。

51-57行，canceled被置为false，同时设置了两个变量newTouchTarget与alreadyDispatchedToNewTouchTarget，其作用如下：

* newTouchTarget，用于保存新发现的可以接收事件分发的子视图的对象。
* alreadyDispatchedToNewTouchTarget，新发现的可以接收事件分发的子视图是否已经接收了事件。

58－68行，由于intercepted与canceled字段此时均为false，因此进入if代码块。在第68行，由于我们当前是ACTION_DOWN手势，因此进入该代码块。

80-89行，这一部分的代码的主要工作是找到一个可以接收事件分发的子视图，若newTouchTarget为null并且子视图的个数不为0的话则开始寻找这样的子视图。***这里要说明一点，在布局文件中，处于同一节点下的视图，若有两个位置重叠，则在后的视图会覆盖在前的视图，因此在为了寻找newTouchTarget而遍历子视图的过程中，遍历的顺序是由后向前***。

107-111，在遍历子视图的过程中需要对子视图是否具备可以接收事件分发的条件进行判断，这一部分代码便是进行这样的工作，通过两个方法的返回值来判断，其描述如下：

* canViewReceivePointerEvents，通过跟进该方法可以看到，若视图是INVISIBLE的且未设置任何动画，那么该方法返回false，其他情况下均返回true。
* isTransformedTouchPointInView，通过ACTION_DOWN手势的坐标判断该点是否在子视图的范围之内，若在范围之内则返回true，否则返回false，显然，若手势点都不在子视图内，子视图也没有必要接收这个事件了。

那么根据这两个方法我们可以知道，子视图具备接收事件分发的条件是：

* ***子视图是VISIBLE的或者为子视图设置了动画。***
* ***子视图包含事件发生的坐标点。***

若子视图不满足这两个条件之中的任何一个，则直接continue跳过当前子视图。

113-119行，根据正在遍历的子视图在链表中查找是否已经存在这样的节点，并将查找结果赋值给newTouchTarget，若存在，则说明该视图已经存在于可以接收事件分发的链表中了，因此直接break跳出循环，若不存在，则继续寻找。

122-141行，在这一部分尝试将事件分发给子视图，调用了dispatchTransformedTouchEvent方法，在这里根据传入的参数值，最终调用了子视图的dispatchTouchEvent方法，如果子视图消费了该事件那么将返回dispatchTransformedTouchEvent将返回true，此时这个子视图便是我们要寻找的可以接收事件分发的对象，因此在第138行，将根据该视图构造TouchTarget，并将此对象从链表头部插入链表，同时修改mFirstTouchTarget为新的表头，之后将alreadyDispatchedToNewTouchTarget修改为true，因为我们已经将事件分发给了该子视图，跳出循环。

150-158行，若经过遍历未寻找到newTouchTarget但链表并不为空，则将newTouchTarget赋值为链表的表尾节点。

163-166行，若链表为空，即没有找到任何可以接收事件分发的子视图，那么直接调用dispatchTransformedTouchEvent方法，并且通过调用的参数可得知，该方法内会调用父类的dispatchTouchEvent方法，并且在一般情况下会调用ViewGroup自身的onTouchEvent方法，即下一层没有需要接收事件分发的视图时，事件分发机制便会将ViewGroup当作一个普通的View一样处理。

172-196行，从表头开始遍历链表，若当前节点为我们刚刚找到的newTouchTarget并且已经向其分发了事件，那么直接将handled置为true并且向后遍历。若不是，则首先判断节点对应的子视图是否需要取消事件分发，这里用到了之前设置的intercepted字段，在不进行任何拦截操作的情况下，intercepted的值为false，接下来，将事件分发给子视图，若子视图消费了此事件，则将handled置为true，再然后，若cancelChild为true，则需要将节点从链表中删除，用到的方法就是一般的链表的删除方法，删除中间的节点或者删除头节点。那么在此部分，我们可以看到，只要由任一子视图接收并消费了事件，那么ViewGroup的dispatchTouchEvent方法的handled会被置为true，即表示事件已被消费并向其上一层返回handled这个值。

#### ***接下来讨论不进行任何事件拦截时的ACTION_MOVE和ACTION_UP事件***

此时事件为ACTION_MOVE或ACTION_UP，那么不再会进入19行的if代码块，在第29行，虽然事件判断为false，但由于之前已经设置了链表为非空，因此仍会进入此代码块并调用onIntercepted方法，由于未做拦截，此时intercepted字段仍未false。

在第58行进入if代码块，在第68行由于不满足判断条件因此不进入if代码块，跳转到163行，由于我们已经设置了非空的链表，因此会再次遍历链表并将事件分发给链表中的子视图，同时根据子视图对相关事件的处理对handled字段进行赋值并返回。

至此，完成了在不进行任何事件拦截以及具有可接收事件的子视图的情况下的事件分发。

## ***在不拦截任何事件以及不具有可接收事件的子视图的情况下***

在这种情况下进行屏幕点击、滑动，控制台输出如下：

{% highlight ruby linenos %}
07-31 11:15:05.241 15777-15777/com.guoyonghui.eventdispatch D/CustomLinearLayout: dispatchTouchEvent ACTION_DOWN
07-31 11:15:05.241 15777-15777/com.guoyonghui.eventdispatch D/CustomLinearLayout: onInterceptTouchEvent ACTION_DOWN
07-31 11:15:05.241 15777-15777/com.guoyonghui.eventdispatch D/CustomLinearLayout: onTouchEvent ACTION_DOWN
{% endhighlight %}

从控制台可以看到，依次调用了ViewGroup中的dispatchTouchEvent、onInterceptTouchEvent、onTouchEvent方法，同样，我们来看一下在这种情况下是怎样的流程。

首先，同样在第19行，进入if代码块，与前面分析的情况无差别，做一些初始化的工作，接下来29行，进入if代码块，由于为做拦截，此时intercepted仍为false，同样地，在第58行、68行，进入该代码块来寻找newTouchEvent，不具有可接收事件的子视图有这样两种情况：

* ViewGroup没有子视图，那么显然不会有任何需要接收事件的子视图
* 用户ACTION_DOWN的位置上不含有可以接收事件的子视图

在这两种情况下，显然，遍历子视图（如果有的话）并不会得到可用的newTouchTarget，因此经过这一部分代码，newTouchTarget以及mFirstTouchTarget均为null，那么在第163行，会进入if代码块，调用dispatchTransformedTouchEvent方法，由于传入的child为null，因此会在dispatchTransformedTouchEvent方法内调用父类也就是View的dispatchTouchEvent方法，最终调用了ViewGroup继承自View的onTouchEvent方法并根据相关方法的返回值对handled进行赋值。

那么，在这里有一个问题，***当我们点击屏幕并在屏幕上滑动并释放时，为什么上面的控制台输出并无ACTION_MOVE以及ACTION_UP的相关信息输出？***

这就需要看到onTouchEvent方法，在下面这一段截取的onTouchEvent方法中我们可以看到，若在if判断中为true，则会对事件进行相关处理最后返回true，若判断为false，则直接返回false，那么ViewGroup中的dispatchTouchEvent的handled值最终会被置为onTouchEvent方法的返回值，由于在我们的布局文件中，并没有给CustomLinearLayout设置clickable、longClickable、contextClickable属性，因此会将handled置为false，并返回给ViewGroup的上一级，即ViewGroup并未消费此ACTION_DOWN事件，在此有一点很重要，***若任何View没有消费ACTION_DOWN事件即在dispatchTouchEvent方法中返回false，那么后续的事件如ACTION_MOVE、ACTION_UP等都不会再发送过来，原因后面会讲***，这便解释了为什么我们在上面的控制台输出中只能看到ACTION_DOWN的信息了。

{% highlight ruby linenos %}
public boolean onTouchEvent(MotionEvent event) {
    
    ...

    if (((viewFlags & CLICKABLE) == CLICKABLE ||
            (viewFlags & LONG_CLICKABLE) == LONG_CLICKABLE) ||
            (viewFlags & CONTEXT_CLICKABLE) == CONTEXT_CLICKABLE) {
        switch (action) {
            case MotionEvent.ACTION_UP:
                ...
                break;

            case MotionEvent.ACTION_DOWN:
                ...
                break;

            case MotionEvent.ACTION_CANCEL:
                ...
                break;

            case MotionEvent.ACTION_MOVE:
                ...
                break;
        }

        return true;
    }

    return false;
}
{% endhighlight %}

## ***重写onInterceptTouchEvent方法***

#### ***拦截ACTION_DOWN事件***

{% highlight ruby linenos %}
@Override
public boolean onInterceptTouchEvent(MotionEvent ev) {
    switch (ev.getAction()) {
        case MotionEvent.ACTION_DOWN:
            Log.d(TAG, "onInterceptTouchEvent ACTION_DOWN");
            return true;
        case MotionEvent.ACTION_MOVE:
            Log.d(TAG, "onInterceptTouchEvent ACTION_MOVE");
            break;
        case MotionEvent.ACTION_UP:
            Log.d(TAG, "onInterceptTouchEvent ACTION_UP");
            break;
    }
    return super.onInterceptTouchEvent(ev);
}

07-31 13:16:12.614 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: dispatchTouchEvent ACTION_DOWN
07-31 13:16:12.614 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: onInterceptTouchEvent ACTION_DOWN
07-31 13:16:12.614 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: onTouchEvent ACTION_DOWN
{% endhighlight %}

重写onInterceptTouchEvent方法拦截ACTION_DOWN事件，控制台输出如上，分析一波。

在第29行开始的if-else代码块中，由于我们拦截了ACTION_DOWN事件，因此intercepted被置为true，那么58行开始的if代码块由于intercepted为true所以不会进入，直接跳转到163行，由于mFirstTouchTarget为null，因此直接调用ViewGroup的onTouchEvent方法，同时由于ViewGroupw未设置clickable、longClickable、contextClickable属性，因此handled会被置为false并向上返回，所以后续的ACTION_MOVE、ACTION_UP等事件不会再传递给ViewGroup。

#### ***拦截ACTION_MOVE事件***

{% highlight ruby linenos %}
@Override
public boolean onInterceptTouchEvent(MotionEvent ev) {
    switch (ev.getAction()) {
        case MotionEvent.ACTION_DOWN:
            Log.d(TAG, "onInterceptTouchEvent ACTION_DOWN");
            break;
        case MotionEvent.ACTION_MOVE:
            Log.d(TAG, "onInterceptTouchEvent ACTION_MOVE");
            return true;
        case MotionEvent.ACTION_UP:
            Log.d(TAG, "onInterceptTouchEvent ACTION_UP");
            break;
    }
    return super.onInterceptTouchEvent(ev);
}

07-31 13:23:14.564 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: dispatchTouchEvent ACTION_DOWN
07-31 13:23:14.564 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: onInterceptTouchEvent ACTION_DOWN
07-31 13:23:14.564 6921-6921/com.guoyonghui.eventdispatch D/CustomButton: dispatchTouchEvent ACTION_DOWN
07-31 13:23:14.564 6921-6921/com.guoyonghui.eventdispatch D/CustomActivity: onTouch ACTION_DOWN
07-31 13:23:14.564 6921-6921/com.guoyonghui.eventdispatch D/CustomButton: onTouchEvent ACTION_DOWN
07-31 13:23:14.644 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: dispatchTouchEvent ACTION_MOVE
07-31 13:23:14.644 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: onInterceptTouchEvent ACTION_MOVE
07-31 13:23:14.644 6921-6921/com.guoyonghui.eventdispatch D/CustomButton: dispatchTouchEvent ACTION_CANCEL
07-31 13:23:14.644 6921-6921/com.guoyonghui.eventdispatch D/CustomButton: onTouchEvent ACTION_CANCEL
07-31 13:23:14.664 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: dispatchTouchEvent ACTION_MOVE
07-31 13:23:14.664 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: onTouchEvent ACTION_MOVE
07-31 13:23:14.714 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: dispatchTouchEvent ACTION_MOVE
07-31 13:23:14.714 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: onTouchEvent ACTION_MOVE
07-31 13:23:14.724 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: dispatchTouchEvent ACTION_MOVE
07-31 13:23:14.724 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: onTouchEvent ACTION_MOVE
07-31 13:23:14.734 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: dispatchTouchEvent ACTION_UP
07-31 13:23:14.734 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: onTouchEvent ACTION_UP
{% endhighlight %}

重写onInterceptTouchEvent方法拦截ACTION_MOVE事件，控制台输出如上，再分析一波。

首先，从控制台输出可以看到，由于未对ACTION_DOWN事件进行拦截，因此ACTION_DOWN事件正常分发。再看到ACTION_MOVE部分，第一次ACTION_MOVE事件，一次调用了dispatchTouchEvent、onInterceptTouchEvent，跟进代码，由于ACTION_DOWN正常分发，因此mFirstTouchTarget被设置为非空，因此在分发ACTION_MOVE时，依然进入29行的if代码块，调用onInterceptTouchEvent方法并将intercepted置为true，那么58行的if代码块便不会再进入，因此直接进入到163行的if-else中，由于mFirstTouchTarget此时不会空，因此进入到else代码块，在对链表的遍历中，由于intercepted为true，因此cancelChild会被置为true，所以链表中的所有节点都将会接收到一个ACTION_CANCEL事件，同时被从链表中删除，经过此步，mFirstTouchTarget被置为空，那么在接收到下一个ACTION_MOVE事件的时候，由于mFirstTouchTarget已经为空，因此不再调用onInterceptTouchEvent方法。intercepted直接被置为true，所以直接进入163行的if代码块并最终调用ViewGroup的onTouchEvent方法，对于最后的ACTION_UP事件同理。

#### ***拦截ACTION_UP事件***

{% highlight ruby linenos %}
@Override
public boolean onInterceptTouchEvent(MotionEvent ev) {
    switch (ev.getAction()) {
        case MotionEvent.ACTION_DOWN:
            Log.d(TAG, "onInterceptTouchEvent ACTION_DOWN");
            break;
        case MotionEvent.ACTION_MOVE:
            Log.d(TAG, "onInterceptTouchEvent ACTION_MOVE");
            break;
        case MotionEvent.ACTION_UP:
            Log.d(TAG, "onInterceptTouchEvent ACTION_UP");
            return true;
    }
    return super.onInterceptTouchEvent(ev);
}

07-31 13:37:02.414 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: dispatchTouchEvent ACTION_DOWN
07-31 13:37:02.414 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: onInterceptTouchEvent ACTION_DOWN
07-31 13:37:02.424 6921-6921/com.guoyonghui.eventdispatch D/CustomButton: dispatchTouchEvent ACTION_DOWN
07-31 13:37:02.424 6921-6921/com.guoyonghui.eventdispatch D/CustomActivity: onTouch ACTION_DOWN
07-31 13:37:02.424 6921-6921/com.guoyonghui.eventdispatch D/CustomButton: onTouchEvent ACTION_DOWN
07-31 13:37:02.434 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: dispatchTouchEvent ACTION_MOVE
07-31 13:37:02.434 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: onInterceptTouchEvent ACTION_MOVE
07-31 13:37:02.434 6921-6921/com.guoyonghui.eventdispatch D/CustomButton: dispatchTouchEvent ACTION_MOVE
07-31 13:37:02.434 6921-6921/com.guoyonghui.eventdispatch D/CustomActivity: onTouch ACTION_MOVE
07-31 13:37:02.434 6921-6921/com.guoyonghui.eventdispatch D/CustomButton: onTouchEvent ACTION_MOVE
07-31 13:37:02.444 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: dispatchTouchEvent ACTION_UP
07-31 13:37:02.444 6921-6921/com.guoyonghui.eventdispatch D/CustomLinearLayout: onInterceptTouchEvent ACTION_UP
07-31 13:37:02.444 6921-6921/com.guoyonghui.eventdispatch D/CustomButton: dispatchTouchEvent ACTION_CANCEL
07-31 13:37:02.444 6921-6921/com.guoyonghui.eventdispatch D/CustomButton: onTouchEvent ACTION_CANCEL
{% endhighlight %}

与前面类似，ACTION_DOWN与ACTION_MOVE均正常分发，最后的ACTION_UP事件由于被拦截，经历了和上一部分中描述类似的过程。

## ***讲一讲为什么若View/ViewGroup未消费ACTION_DOWN事件则后续的事件也不会分发给它***

首先做个测试。
{% highlight ruby linenos%}
<com.guoyonghui.eventdispatch.view.CustomLinearLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:gravity="center"
    android:orientation="vertical"
    android:clickable="true"
    android:paddingBottom="@dimen/activity_vertical_margin"
    android:paddingLeft="@dimen/activity_horizontal_margin"
    android:paddingRight="@dimen/activity_horizontal_margin"
    android:paddingTop="@dimen/activity_vertical_margin"
    tools:context="com.guoyonghui.eventdispatch.MainActivity">

    <com.guoyonghui.eventdispatch.view.CustomButton
        android:id="@+id/click"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:longClickable="true"
        android:text="@string/app_name"
        android:textAllCaps="false"/>

</com.guoyonghui.eventdispatch.view.CustomLinearLayout>

@Override
public boolean onTouchEvent(MotionEvent event) {
switch (event.getAction()) {
    case MotionEvent.ACTION_DOWN:
        Log.d(TAG, "onTouchEvent ACTION_DOWN");
        return false;
    case MotionEvent.ACTION_MOVE:
        Log.d(TAG, "onTouchEvent ACTION_MOVE");
        break;
    case MotionEvent.ACTION_UP:
        Log.d(TAG, "onTouchEvent ACTION_UP");
        break;
    case MotionEvent.ACTION_CANCEL:
        Log.d(TAG, "onTouchEvent ACTION_CANCEL");
        break;
}

return super.onTouchEvent(event);
}

07-31 14:01:57.274 19605-19605/com.guoyonghui.eventdispatch D/CustomLinearLayout: dispatchTouchEvent ACTION_DOWN
07-31 14:01:57.274 19605-19605/com.guoyonghui.eventdispatch D/CustomLinearLayout: onInterceptTouchEvent ACTION_DOWN
07-31 14:01:57.274 19605-19605/com.guoyonghui.eventdispatch D/CustomButton: dispatchTouchEvent ACTION_DOWN
07-31 14:01:57.274 19605-19605/com.guoyonghui.eventdispatch D/CustomActivity: onTouch ACTION_DOWN
07-31 14:01:57.274 19605-19605/com.guoyonghui.eventdispatch D/CustomButton: onTouchEvent ACTION_DOWN
07-31 14:01:57.274 19605-19605/com.guoyonghui.eventdispatch D/CustomLinearLayout: onTouchEvent ACTION_DOWN
07-31 14:01:57.294 19605-19605/com.guoyonghui.eventdispatch D/CustomLinearLayout: dispatchTouchEvent ACTION_MOVE
07-31 14:01:57.294 19605-19605/com.guoyonghui.eventdispatch D/CustomLinearLayout: onTouchEvent ACTION_MOVE
07-31 14:01:57.294 19605-19605/com.guoyonghui.eventdispatch D/CustomLinearLayout: dispatchTouchEvent ACTION_UP
07-31 14:01:57.294 19605-19605/com.guoyonghui.eventdispatch D/CustomLinearLayout: onTouchEvent ACTION_UP
{% endhighlight %}

更改一下布局文件，给CustomLinearLayout增加`android:clickable="true"`属性，使其能够在onTouchEvent中处理事件并向上返回true，同时，重写CustomButton的onTouchEvent方法，当处理的事件为ACTION_DOWN时返回false，最后贴出控制台输出。

首先，经过上面的叙述我们已经可以知道，需要ViewGroup向下分发事件的子视图对象维护在一个TouchTarget类型的链表中，子视图作为目标对象被加入到链表中当且仅当子视图的dispatchTouchEvent在分发ACTION_DOWN事件时返回true（即消费了ACTION_DOWN事件），那么，当子视图未消费ACTION_DOWN事件时，它便不会被加入到链表之中，而后续事件如ACTION_MOVE、ACTION_UP等都是通过遍历链表来进行分发（如果链表不为空的话，为空则直接将事件分发给ViewGroup的onTouchEvent），因此未消费ACTION_DOWN的子视图是得不到后续事件的分发的。

ViewGroup是View的子类，因此若ViewGroup的dispatchTouchEvent在分发ACTION_DOWN事件时返回false未进行消费，同样得不到后续事件，原理和上面是一样的，和View的区别在于View只需判断自己是否消费了该事件，而ViewGroup需判断是否有子视图消费了该事件，若有则代表自己也消费了此事件，若没有再去调用自己的onTouchEvent来判断自己是否消费了该事件。

同时，通过分析源码容易知道，若视图在分发ACTION_MOVE事件时返回false是不会影响后续事件继续发送过来的。

至此，对ViewGroup的事件分发机制便有了一个大致的了解，嗨呀。

***[Source Code](https://github.com/Guomato/TouchEventLearning)***