---
layout: post
title:  "[Android] View事件分发机制"
date:   2016-07-24 18:30:54 +0800
categories: Android
---

本文将主要讨论View和ViewGroup的事件分发机制，首先，通过自定义继承自Button的按钮控件来观察事件分发相关函数调用的过程。

CustomButton.java
{% highlight bash linenos %}
public class CustomButton extends Button {

    private static final String TAG = CustomButton.class.getSimpleName();

    public CustomButton(Context context) {
        super(context);
    }

    public CustomButton(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public CustomButton(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @Override
    public boolean dispatchTouchEvent(MotionEvent event) {
        switch (event.getAction()) {
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

        return super.dispatchTouchEvent(event);
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        switch (event.getAction()) {
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
        return super.onTouchEvent(event);
    }
}
{% endhighlight %}

MainActivity.java
{% highlight bash linenos %}
public class MainActivity extends AppCompatActivity implements View.OnTouchListener, View.OnClickListener, View.OnLongClickListener {

    private static final String TAG = MainActivity.class.getSimpleName();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Button button = (Button) findViewById(R.id.click);
        button.setOnTouchListener(this);
        button.setOnClickListener(this);
        button.setOnLongClickListener(this);
    }

    @Override
    public void onClick(View v) {
        Log.d(TAG, "onClick");
    }

    @Override
    public boolean onLongClick(View v) {
        Log.d(TAG, "onLongClick");

        return true;
    }

    @Override
    public boolean onTouch(View v, MotionEvent event) {
        switch (event.getAction()) {
            case MotionEvent.ACTION_DOWN:
                Log.d(TAG, "onTouch ACTION_DOWN");
                break;
            case MotionEvent.ACTION_MOVE:
                Log.d(TAG, "onTouch ACTION_MOVE");
                break;
            case MotionEvent.ACTION_UP:
                Log.d(TAG, "onTouch ACTION_UP");
                break;
        }
        return false;
    }
}
{% endhighlight %}

activity_main.xml
{% highlight bash linenos %}
<RelativeLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:paddingBottom="@dimen/activity_vertical_margin"
    android:paddingLeft="@dimen/activity_horizontal_margin"
    android:paddingRight="@dimen/activity_horizontal_margin"
    android:paddingTop="@dimen/activity_vertical_margin"
    tools:context="com.guoyonghui.eventdispatch.MainActivity">

    <com.guoyonghui.eventdispatch.view.CustomButton
        android:id="@+id/click"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_centerInParent="true"
        android:longClickable="true"
        android:text="@string/app_name"
        android:textAllCaps="false"/>

</RelativeLayout>
{% endhighlight %}

点击按钮后的控制台输出
{% highlight bash linenos %}
07-24 18:45:33.470 6930-6930/com.guoyonghui.eventdispatch D/CustomButton: dispatchTouchEvent ACTION_DOWN
07-24 18:45:33.470 6930-6930/com.guoyonghui.eventdispatch D/MainActivity: onTouch ACTION_DOWN
07-24 18:45:33.470 6930-6930/com.guoyonghui.eventdispatch D/CustomButton: onTouchEvent ACTION_DOWN
07-24 18:45:33.490 6930-6930/com.guoyonghui.eventdispatch D/CustomButton: dispatchTouchEvent ACTION_UP
07-24 18:45:33.490 6930-6930/com.guoyonghui.eventdispatch D/MainActivity: onTouch ACTION_UP
07-24 18:45:33.490 6930-6930/com.guoyonghui.eventdispatch D/CustomButton: onTouchEvent ACTION_UP
07-24 18:45:33.500 6930-6930/com.guoyonghui.eventdispatch D/MainActivity: onClick
{% endhighlight %}

从控制台输出可以看出事件传递的基本过程是：
dispatchTouchEvent
OnTouchListener中的onTouch
onTouchEvent

下面跟进View.java中的相关函数。

View.java中的dispatchTouchEvent函数
{% highlight bash linenos %}
public boolean dispatchTouchEvent(MotionEvent event) {
    if (event.isTargetAccessibilityFocus()) {
        if (!isAccessibilityFocusedViewOrHost()) {
            return false;
        }
        event.setTargetAccessibilityFocus(false);
    }

    boolean result = false;

    if (mInputEventConsistencyVerifier != null) {
        mInputEventConsistencyVerifier.onTouchEvent(event, 0);
    }

    final int actionMasked = event.getActionMasked();
    if (actionMasked == MotionEvent.ACTION_DOWN) {
        stopNestedScroll();
    }

    if (onFilterTouchEventForSecurity(event)) {
        ListenerInfo li = mListenerInfo;
        if (li != null && li.mOnTouchListener != null
                && (mViewFlags & ENABLED_MASK) == ENABLED
                && li.mOnTouchListener.onTouch(this, event)) {
            result = true;
        }

        if (!result && onTouchEvent(event)) {
            result = true;
        }
    }

    if (!result && mInputEventConsistencyVerifier != null) {
        mInputEventConsistencyVerifier.onUnhandledEvent(event, 0);
    }

    if (actionMasked == MotionEvent.ACTION_UP ||
            actionMasked == MotionEvent.ACTION_CANCEL ||
            (actionMasked == MotionEvent.ACTION_DOWN && !result)) {
        stopNestedScroll();
    }

    return result;
}
{% endhighlight %}

20-31行是比较重要的一段逻辑。

在第22行，判断ListenerInfo是否为空、为该控件设置的OnTouchListener是否为空（当没有给该控件设置此类型监听时判断为false）、该控件是否被置为enable，最后一个判定条件为当控件的OnTouchListener不为空时回调函数onTouch的返回值，若onTouch函数返回true则表示该事件已被消费因此result将被置为true，若onTouch函数返回false则表示该事件仍需继续传递因此result将被置为false。

28－30行，在这部分可以看到，若事件被OnTouchListener中的onTouch函数消费，那么result被置为true，则onTouchEvent方法不会被调用，而若事件未在上一步中被消费，则result被置为false，此时onTouchEvent方法被调用，并根据该方法的返回值判断是否对result进行设置，若onTouchEvent返回true则表示事件被该方法消费，result被置为true，否则result仍保持false。

这便对应了上面的控制台的函数的调用顺序，下面通过将onTouch函数的返回值设置为true（消费该事件）来验证上述描述。

验证过程
{% highlight bash linenos %}
@Override
public boolean onTouch(View v, MotionEvent event) {
    switch (event.getAction()) {
        case MotionEvent.ACTION_DOWN:
            Log.d(TAG, "onTouch ACTION_DOWN");
            break;
        case MotionEvent.ACTION_MOVE:
            Log.d(TAG, "onTouch ACTION_MOVE");
            break;
        case MotionEvent.ACTION_UP:
            Log.d(TAG, "onTouch ACTION_UP");
            break;
    }
    return true;
}

07-24 19:21:08.530 20498-20498/com.guoyonghui.eventdispatch D/CustomButton: dispatchTouchEvent ACTION_DOWN
07-24 19:21:08.530 20498-20498/com.guoyonghui.eventdispatch D/MainActivity: onTouch ACTION_DOWN
07-24 19:21:08.540 20498-20498/com.guoyonghui.eventdispatch D/CustomButton: dispatchTouchEvent ACTION_UP
07-24 19:21:08.540 20498-20498/com.guoyonghui.eventdispatch D/MainActivity: onTouch ACTION_UP
{% endhighlight %}

下面对onTouchEvent函数进行探究。

{% highlight bash linenos %}
public void onTouchEvent(MotionEvent event, int nestingLevel) {
    if (!startEvent(event, nestingLevel, EVENT_TYPE_TOUCH)) {
        return;
    }

    final int action = event.getAction();
    final boolean newStream = action == MotionEvent.ACTION_DOWN
            || action == MotionEvent.ACTION_CANCEL || action == MotionEvent.ACTION_OUTSIDE;
    if (newStream && (mTouchEventStreamIsTainted || mTouchEventStreamUnhandled)) {
        mTouchEventStreamIsTainted = false;
        mTouchEventStreamUnhandled = false;
        mTouchEventStreamPointers = 0;
    }
    if (mTouchEventStreamIsTainted) {
        event.setTainted(true);
    }

    try {
        ensureMetaStateIsNormalized(event.getMetaState());

        final int deviceId = event.getDeviceId();
        final int source = event.getSource();

        if (!newStream && mTouchEventStreamDeviceId != -1
                && (mTouchEventStreamDeviceId != deviceId
                        || mTouchEventStreamSource != source)) {
            problem("Touch event stream contains events from multiple sources: "
                    + "previous device id " + mTouchEventStreamDeviceId
                    + ", previous source " + Integer.toHexString(mTouchEventStreamSource)
                    + ", new device id " + deviceId
                    + ", new source " + Integer.toHexString(source));
        }
        mTouchEventStreamDeviceId = deviceId;
        mTouchEventStreamSource = source;

        final int pointerCount = event.getPointerCount();
        if ((source & InputDevice.SOURCE_CLASS_POINTER) != 0) {
            switch (action) {
                case MotionEvent.ACTION_DOWN:
                    if (mTouchEventStreamPointers != 0) {
                        problem("ACTION_DOWN but pointers are already down.  "
                                + "Probably missing ACTION_UP from previous gesture.");
                    }
                    ensureHistorySizeIsZeroForThisAction(event);
                    ensurePointerCountIsOneForThisAction(event);
                    mTouchEventStreamPointers = 1 << event.getPointerId(0);
                    break;
                case MotionEvent.ACTION_UP:
                    ensureHistorySizeIsZeroForThisAction(event);
                    ensurePointerCountIsOneForThisAction(event);
                    mTouchEventStreamPointers = 0;
                    mTouchEventStreamIsTainted = false;
                    break;
                case MotionEvent.ACTION_MOVE: {
                    final int expectedPointerCount =
                            Integer.bitCount(mTouchEventStreamPointers);
                    if (pointerCount != expectedPointerCount) {
                        problem("ACTION_MOVE contained " + pointerCount
                                + " pointers but there are currently "
                                + expectedPointerCount + " pointers down.");
                        mTouchEventStreamIsTainted = true;
                    }
                    break;
                }
                case MotionEvent.ACTION_CANCEL:
                    mTouchEventStreamPointers = 0;
                    mTouchEventStreamIsTainted = false;
                    break;
                case MotionEvent.ACTION_OUTSIDE:
                    if (mTouchEventStreamPointers != 0) {
                        problem("ACTION_OUTSIDE but pointers are still down.");
                    }
                    ensureHistorySizeIsZeroForThisAction(event);
                    ensurePointerCountIsOneForThisAction(event);
                    mTouchEventStreamIsTainted = false;
                    break;
                default: {
                    final int actionMasked = event.getActionMasked();
                    final int actionIndex = event.getActionIndex();
                    if (actionMasked == MotionEvent.ACTION_POINTER_DOWN) {
                        if (mTouchEventStreamPointers == 0) {
                            problem("ACTION_POINTER_DOWN but no other pointers were down.");
                            mTouchEventStreamIsTainted = true;
                        }
                        if (actionIndex < 0 || actionIndex >= pointerCount) {
                            problem("ACTION_POINTER_DOWN index is " + actionIndex
                                    + " but the pointer count is " + pointerCount + ".");
                            mTouchEventStreamIsTainted = true;
                        } else {
                            final int id = event.getPointerId(actionIndex);
                            final int idBit = 1 << id;
                            if ((mTouchEventStreamPointers & idBit) != 0) {
                                problem("ACTION_POINTER_DOWN specified pointer id " + id
                                        + " which is already down.");
                                mTouchEventStreamIsTainted = true;
                            } else {
                                mTouchEventStreamPointers |= idBit;
                            }
                        }
                        ensureHistorySizeIsZeroForThisAction(event);
                    } else if (actionMasked == MotionEvent.ACTION_POINTER_UP) {
                        if (actionIndex < 0 || actionIndex >= pointerCount) {
                            problem("ACTION_POINTER_UP index is " + actionIndex
                                    + " but the pointer count is " + pointerCount + ".");
                            mTouchEventStreamIsTainted = true;
                        } else {
                            final int id = event.getPointerId(actionIndex);
                            final int idBit = 1 << id;
                            if ((mTouchEventStreamPointers & idBit) == 0) {
                                problem("ACTION_POINTER_UP specified pointer id " + id
                                        + " which is not currently down.");
                                mTouchEventStreamIsTainted = true;
                            } else {
                                mTouchEventStreamPointers &= ~idBit;
                            }
                        }
                        ensureHistorySizeIsZeroForThisAction(event);
                    } else {
                        problem("Invalid action " + MotionEvent.actionToString(action)
                                + " for touch event.");
                    }
                    break;
                }
            }
        } else {
            problem("Source was not SOURCE_CLASS_POINTER.");
        }
    } finally {
        finishEvent();
    }
}
{% endhighlight %}