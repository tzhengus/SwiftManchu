package com.tzheng.swiftmanchu;

import android.app.Activity;
import android.os.Bundle;
import android.view.Gravity;
import android.widget.TextView;

public final class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        TextView title = new TextView(this);
        title.setGravity(Gravity.CENTER);
        title.setText("SwiftManchu");
        title.setTextSize(24);
        setContentView(title);
    }
}
