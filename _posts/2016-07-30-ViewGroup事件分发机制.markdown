---
layout: post
title: "ViewGroup事件分发机制"
author: Guomato
date: 2016-07-30 17:30:26 +0800
categories: ViewGroup Android
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

19-25行，首先我们可以很容易知道，用户触摸屏幕的一系列手势的开始一定是ACTION_DOWN手势，这一部分代码便是在一系列手势开始的时候进行一些初始化工作，跟进cancelAndClearTouchTargets方法，该方法中涉及一个叫做TouchTarget的类，从类名中我们可以看出这个类的作用大致是充当手势的目标对象，该类中维持了一个TouchTarget类型的next字段，因此我认为该类类似于一个链表，链表中的第一个节点为事件应第一个分发的视图，其后的每个节点会依次得到该事件。在cancelAndClearTouchTargets方法中，依次向链表中的每一个对象分发了一个ACTION_CANCEL事件，之后通过一个循环将链表中的节点重置，并将mFirstTouchTarget字段置为null，之后在该方法中会调用resetTouchState方法为mGroupFlags取消FLAG_DISALLOW_INTERCEPT标志，通过在ACTION_DOWN手势下调用cancelAndClearTouchTargets完成了一些初始化的工作。

28-42行，当用户按下或者mFirstTouchTarget不为null的时候进入此代码块，分两种情况讨论：

* 若是用户刚刚按下时，此时mGroupFlags经过cancelAndClearTouchTargets方法的调用已经取消FLAG_DISALLOW_INTERCEPT标志，因此disallowIntercept会被置为false，即允许拦截，因此此时onInterceptTouchEvent方法一定会被调用，intercepted字段被置为该方法的返回值。
* 若是由mFirstTouchTarget不为null进入，TODO

51-58行，首先对canceled字段进行赋值，若事件为ACTION_CANCEL或之前已经设置过了PFLAG_CANCEL_NEXT_UP_EVENT标志则将canceled置为true，否则置为false，在第58行根据canceled和intercepted字段的值判断是否进入代码块，当且仅当ViewGroup既没有拦截该事件同时该事件不是一个cancel事件时才进入if代码块，否则进入else代码块。

81-82行，两行代码用于获取用户手势的横纵坐标。

88-89行，对该ViewGroup的子View进行扫描。

107-111行，调用了两个方法，canViewReceivePointerEvents和isTransformedTouchPointInView方法，第一个方法用于判断子视图是否可见以及是否设置了动画，若不可见且未设置动画则返回false，其余情况返回true。第二个方法用于判断用户手势的坐标点是否在子视图所处的位置内，若子视图处于该位置中则返回true，否则返回false。根据if的条件我们可以看到，若子视图是不可见的且未设置动画或者子视图的范围并不包括手势点时，子视图不应该接收事件分发，因此直接continue到下一个子视图。

113-119行，根据子视图从TouchTarget链表中查找相应的对象，当手势刚刚开始发生时，由于mFirstTouchTarget为null，因此此时newTouchTarget一定为null。

122-141行，这一段中调用了dispatchTransformedTouchEvent方法，若子视图不为null并且子视图最终消费了此事件则进入代码块，在代码块中为当前的子视图创建TouchTarget并插入链表头，同时将mFirstTouchTarget置为表头，之后跳出循环，即一旦找到可以接收事件的视图则停止对子视图的扫描（由于在布局文件中后布局的视图会覆盖前面布局的视图所以对子视图的扫描是从后向前扫描）。

150行，若未找到新的可以接收事件分发的对象但mFirstTouchTarget不为null，则将newTouchTarget置为链表的链尾。

163行， 若未找到任何可接收事件分发的子视图，则将事件传递给ViewGroup自身的onTouchEvent方法。

168行，若事件分发链表不为空，定义两个变量，predecessor和target，第一个是上一个处理过的target，置为null，第二个是当前正在处理的target，显然我们需要把该变量置为mFirstTouchTarget，接下来是一个循环处理，当target不为空，即存在我们需要进行事件分发的子视图时，进入循环进行处理，接下来的第一个if判断，当alreadyDispatchedToNewTouchTarget为true并且target为newTouchTarget时，由于在找到新的事件分发对象时，我们已经将事件分发给了该对象对应的子视图，因此alreadyDispatchedToNewTouchTarget会被置为true，此时我们无需再次进行事件分发，直接将handled置为true，若if判断为否的话，进入else对应的代码块，此时需要对cancelChild进行赋值，接下来将事件分发给子视图，若子视图消费了该事件则将handled置为true（即，只要布局于该ViewGroup内的子视图其中的任何一个视图消费了此事件，那么handled都将被置为true，表示该ViewGroup消费了此事件），接下来，若之前设置的cancelChild为true即取消该子视图，那么若predecessor为空即当前target为链表头，那么将mFirstTouchTarget置为当前target的next用来表示当前target已被取消，若predecessor不为空，则直接将predecessor的next字段置为当前target的next，同样表示当前target已被取消，之后再对链表进行遍历的话便不会遍历到这个已被取消的target，之后将当前目标recycle掉并把target变量置为当前节点的下一节点即可。若不需要取消当前target，则将predecessor置为当前节点，当前节点置为下一节点即可，直至遍历完链表中的所有节点为止，这样，便完成了事件从当前ViewGroup到其child View/ViewGroup的分发。

































