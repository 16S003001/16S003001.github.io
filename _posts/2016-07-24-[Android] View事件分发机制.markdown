---
layout: post
title:  "[Android] View事件分发机制"
date:   2016-07-24 18:30:54 +0800
categories: Android
---

本文将主要讨论View的事件分发机制，首先，通过自定义继承自Button的按钮控件来观察事件分发相关函数调用的过程。

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