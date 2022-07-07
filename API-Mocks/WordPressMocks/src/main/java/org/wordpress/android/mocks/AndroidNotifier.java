package org.wordpress.android.mocks;

import android.util.Log;

import com.github.tomakehurst.wiremock.common.Notifier;

public class AndroidNotifier implements Notifier {
    private static final String TAG = "WordPressMocks";

    @Override public void info(String message) {
        Log.i(TAG, message);
    }

    @Override public void error(String message) {
        Log.e(TAG, message);
    }

    @Override public void error(String message, Throwable t) {
        Log.e(TAG, message, t);
    }
}
