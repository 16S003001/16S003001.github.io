---
layout: post
title:  "[Android] View事件分发机制"
date:   2016-07-24 18:30:54 +0800
categories: Android
---

本文将主要讨论View的事件分发机制，首先，通过自定义继承自Button的按钮控件来观察事件分发相关方法调用的过程。

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

下面跟进View.java中的相关方法。

View.java中的dispatchTouchEvent方法
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

22行，判断ListenerInfo是否为空、为该控件设置的OnTouchListener是否为空（当没有给该控件设置此类型监听时判断为false）、该控件是否被置为enable，最后一个判定条件为当控件的OnTouchListener不为空时回调方法onTouch的返回值，若onTouch方法返回true则表示该事件已被消费因此result将被置为true，若onTouch方法返回false则表示该事件仍需继续传递因此result将被置为false。

28－30行，在这部分可以看到，若事件被OnTouchListener中的onTouch方法消费，那么result被置为true，则onTouchEvent方法不会被调用，而若事件未在上一步中被消费，则result被置为false，此时onTouchEvent方法被调用，并根据该方法的返回值判断是否对result进行设置，若onTouchEvent返回true则表示事件被该方法消费，result被置为true，否则result仍保持false。

这便对应了上面的控制台的方法的调用顺序，下面通过将onTouch方法的返回值设置为true（消费该事件）来验证上述描述。

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

下面对onTouchEvent方法进行探究。

View.java中的onTouchEvent方法
{% highlight bash linenos %}
public boolean onTouchEvent(MotionEvent event) {
    final float x = event.getX();
    final float y = event.getY();
    final int viewFlags = mViewFlags;
    final int action = event.getAction();

    if ((viewFlags & ENABLED_MASK) == DISABLED) {
        if (action == MotionEvent.ACTION_UP && (mPrivateFlags & PFLAG_PRESSED) != 0) {
            setPressed(false);
        }
        return (((viewFlags & CLICKABLE) == CLICKABLE
                || (viewFlags & LONG_CLICKABLE) == LONG_CLICKABLE)
                || (viewFlags & CONTEXT_CLICKABLE) == CONTEXT_CLICKABLE);
    }

    if (mTouchDelegate != null) {
        if (mTouchDelegate.onTouchEvent(event)) {
            return true;
        }
    }

    if (((viewFlags & CLICKABLE) == CLICKABLE ||
            (viewFlags & LONG_CLICKABLE) == LONG_CLICKABLE) ||
            (viewFlags & CONTEXT_CLICKABLE) == CONTEXT_CLICKABLE) {
        switch (action) {
            case MotionEvent.ACTION_UP:
                boolean prepressed = (mPrivateFlags & PFLAG_PREPRESSED) != 0;
                if ((mPrivateFlags & PFLAG_PRESSED) != 0 || prepressed) {
                    boolean focusTaken = false;
                    if (isFocusable() && isFocusableInTouchMode() && !isFocused()) {
                        focusTaken = requestFocus();
                    }

                    if (prepressed) {
                        setPressed(true, x, y);
                   }

                    if (!mHasPerformedLongPress && !mIgnoreNextUpEvent) {
                        removeLongPressCallback();

                        if (!focusTaken) {
                            if (mPerformClick == null) {
                                mPerformClick = new PerformClick();
                            }
                            if (!post(mPerformClick)) {
                                performClick();
                            }
                        }
                    }

                    if (mUnsetPressedState == null) {
                        mUnsetPressedState = new UnsetPressedState();
                    }

                    if (prepressed) {
                        postDelayed(mUnsetPressedState,
                                ViewConfiguration.getPressedStateDuration());
                    } else if (!post(mUnsetPressedState)) {
                        mUnsetPressedState.run();
                    }

                    removeTapCallback();
                }
                mIgnoreNextUpEvent = false;
                break;

            case MotionEvent.ACTION_DOWN:
                mHasPerformedLongPress = false;

                if (performButtonActionOnTouchDown(event)) {
                    break;
                }

                boolean isInScrollingContainer = isInScrollingContainer();

                if (isInScrollingContainer) {
                    mPrivateFlags |= PFLAG_PREPRESSED;
                    if (mPendingCheckForTap == null) {
                        mPendingCheckForTap = new CheckForTap();
                    }
                    mPendingCheckForTap.x = event.getX();
                    mPendingCheckForTap.y = event.getY();
                    postDelayed(mPendingCheckForTap, ViewConfiguration.getTapTimeout());
                } else {
                    setPressed(true, x, y);
                    checkForLongClick(0);
                }
                break;

            case MotionEvent.ACTION_CANCEL:
                setPressed(false);
                removeTapCallback();
                removeLongPressCallback();
                mInContextButtonPress = false;
                mHasPerformedLongPress = false;
                mIgnoreNextUpEvent = false;
                break;

            case MotionEvent.ACTION_MOVE:
                drawableHotspotChanged(x, y);

                if (!pointInView(x, y, mTouchSlop)) {
                    removeTapCallback();
                    if ((mPrivateFlags & PFLAG_PRESSED) != 0) {
                        removeLongPressCallback();

                        setPressed(false);
                    }
                }
                break;
        }

        return true;
    }

    return false;
}
{% endhighlight %}

7-14行，View被设为disabled时，当用户当前操作为抬起手势并且flag为PRESSED时取消flag的PRESSED标志并刷新背景，同时根据控件是否可点击、是否可长按、是否为上下文按钮返回相应值。

16-20行，若控件使用了Touch代理，则若代理消费了此事件直接返回true。

接下来时根据用户的手势进行相应的逻辑判定。

当用户按下即event.getAction为ACTION_DOWN时，进入67行起的一段代码，首先将mHasPerformedLongPress（是否进行了长按操作）置为false，接下来对控件是否处于可滑动的容器之中进行判断：

* 若是，将mPrivateFlags置为PFLAG_PREPRESSED，并开始使用CheckForTap进行检测，延时100ms（TAP_TIMEOUT）执行（由于控件处于可滑动的容器之中，因此需要判断用户当前的手势是一次点击还是一次滑动，若用户在TAP_TIMEOUT时间间隔内未进行移出控件手势操作，则判定当前手势为一次点击）。
* 若否，将mPrivateFlags置为PFLAG_PRESSED，并刷新背景，同时开始使用CheckForLongPress进行长按检测，延时500ms执行以判断是否为长按手势。

然后对上面提到的CheckForTap和CheckForLongPress两个类进行说明：

* CheckForTap，用于检测手势是点击事件还是滑动事件，使用postDelayed延时100ms执行，若用户未在该时间段内移出当前点击控件则被认定为是一次点击事件，该Runnable得到执行，在CheckForTap中会取消mPrivateFlags的PFLAG_PREPRESSED标志而将其设置为PFLAG_PRESSED，并刷新控件背景，同时会使用checkForLongClick方法进行长按检测，在checkForLongClick方法中首先对控件是否支持长按事件进行判断，若支持首先将mHasPerformedLongPress设为false，然后使用CheckForLongPress进行长按检测，延时400ms进行（由于DEFAULT_LONG_PRESS_TIMEOUT即默认的长按时长为500ms，而之前进行滑动／点击检测已经耗费100ms，因此若为点击事件再执行长按检测，需去除之前耗费的100ms，即延时400ms）。
{% highlight bash linenos %}
private final class CheckForTap implements Runnable {
    public float x;
    public float y;

    @Override
    public void run() {
        mPrivateFlags &= ~PFLAG_PREPRESSED;
        setPressed(true, x, y);
        checkForLongClick(ViewConfiguration.getTapTimeout());
    }
}

private void checkForLongClick(int delayOffset) {
    if ((mViewFlags & LONG_CLICKABLE) == LONG_CLICKABLE) {
        mHasPerformedLongPress = false;

        if (mPendingCheckForLongPress == null) {
            mPendingCheckForLongPress = new CheckForLongPress();
        }
        mPendingCheckForLongPress.rememberWindowAttachCount();
        postDelayed(mPendingCheckForLongPress,
                ViewConfiguration.getLongPressTimeout() - delayOffset);
    }
}
{% endhighlight %}

* CheckForLongPress，用于检测手势是否为长按事件，在该Runnable中会使用performLongClick方法的返回值，在performLongClick中判断是否为该控件设置了OnLongClickListener，如果设置了则将该方法的返回值置为OnLongClickListener的回调方法onLongClick的返回值，若在onLongClick方法中消费了此事件即返回true，那么performLongClick方法也将返回true，那么mHasPerformedLongPress将会被置为true，若onLongClick方法返回false那么mHasPerformedLongPress仍被置为false。
{% highlight bash linenos %}
private final class CheckForLongPress implements Runnable {
    private int mOriginalWindowAttachCount;

    @Override
    public void run() {
        if (isPressed() && (mParent != null)
                && mOriginalWindowAttachCount == mWindowAttachCount) {
            if (performLongClick()) {
                mHasPerformedLongPress = true;
            }
        }
    }

    public void rememberWindowAttachCount() {
        mOriginalWindowAttachCount = mWindowAttachCount;
    }
}

public boolean performLongClick() {
    sendAccessibilityEvent(AccessibilityEvent.TYPE_VIEW_LONG_CLICKED);

    boolean handled = false;
    ListenerInfo li = mListenerInfo;
    if (li != null && li.mOnLongClickListener != null) {
        handled = li.mOnLongClickListener.onLongClick(View.this);
    }
    if (!handled) {
        handled = showContextMenu();
    }
    if (handled) {
        performHapticFeedback(HapticFeedbackConstants.LONG_PRESS);
    }
    return handled;
}
{% endhighlight %}

当用户移动即event.getAction为ACTION_MOVE时，进入99行起的一段代码，当用户滑动时，在102行会判断用户是否滑出控件，如果滑出控件则移除之前设置的CheckForTap（若从用户按下到滑出控件还未到100ms那么CheckForTap不会被执行，即被认为是滑动而不是点击），若超过了100ms则CheckForTap已经执行，mPrivateFlags被置为PFLAG_PRESSED，则进入104行内，移除之前设置的CheckForLongPress，并将mPrivateFlags置为空。

下面看当用户抬起手势即event.getAction为ACTION_UP时的代码，此时进入26行起的一段代码。

30-32行用于获取焦点。

34-36行，若prepressed为true，即我在我们还未检测到事件是一次点击还是一次活动时用户便抬起手势释放了按钮，此时我们仍需刷新背景以向用户显示点击效果，同时设置mPrivateFlags为PFLAG_PRESSED。

38-49行，若mHasPerformedLongPress为false则进入此代码块，mHasPerformedLongPress为false存在两种情况，一种是还未达到长按的默认时长即500ms用户便释放了按钮，此时需要移除长按检测，另一种是达到了长按的默认时长但是长按事件的监听器的回调方法返回值为false，此时mHasPerformedLongPress也为false，在mHasPerformedLongPress为false即没有触发长按事件时会触发点击事件，即调用performClick方法，在此方法中会调用为此控件设置的OnClickListener的回调函数onClick。到这里我们可以看出，如果我们长按控件并且在OnLongClickListener的onLongClick方法中消费了此事件即返回true，那么控件的OnClickListener的回调方法onClick便不会再被调用，在下面的代码中我们在onLongClick方法中返回true，可以看到，onClick方法未被调用。

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

07-25 09:57:03.758 28610-28610/com.guoyonghui.eventdispatch D/CustomButton: dispatchTouchEvent ACTION_DOWN
07-25 09:57:03.758 28610-28610/com.guoyonghui.eventdispatch D/MainActivity: onTouch ACTION_DOWN
07-25 09:57:03.758 28610-28610/com.guoyonghui.eventdispatch D/CustomButton: onTouchEvent ACTION_DOWN
07-25 09:57:04.258 28610-28610/com.guoyonghui.eventdispatch D/MainActivity: onLongClick
07-25 09:57:04.458 28610-28610/com.guoyonghui.eventdispatch D/CustomButton: dispatchTouchEvent ACTION_UP
07-25 09:57:04.458 28610-28610/com.guoyonghui.eventdispatch D/MainActivity: onTouch ACTION_UP
07-25 09:57:04.458 28610-28610/com.guoyonghui.eventdispatch D/CustomButton: onTouchEvent ACTION_UP
{% endhighlight %}

接下来我们看到51-62行，这部分首先实例化了一个UnsetPressedState，这个类用来取消控件的PFLAG_PRESSED标志并且刷新背景，在之后的判断中，若用户是在100ms内释放了控件，那么需要延时运行该Runnable，否则的话立即运行该Runnable，最后清除之前设置的滑动／点击检测。

至此，View类的事件分发机制探索完毕。















