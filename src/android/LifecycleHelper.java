package com.bit6.ChatDemo;

import android.os.Handler;
import com.bit6.sdk.Bit6;

public final class LifecycleHelper {

	private boolean foreground, paused = true;
	private Handler handler = new Handler();
	private Runnable check;
	private long CHECK_DELAY = 5000;
	private Bit6 bit6;

	private static LifecycleHelper instance = null;

	protected LifecycleHelper() {
		this.bit6 = Bit6.getInstance();//bit6;
	}

	 public static LifecycleHelper getInstance() {
      if(instance == null) {
         instance = new LifecycleHelper();
      }
      return instance;
   }

	public void onForeground() {
		paused = false;
		boolean wasBackground = !foreground;
		foreground = true;

		if (check != null)
			handler.removeCallbacks(check);

		if (wasBackground) {
			bit6.onForeground();
		}
	}

	public void onBackground() {
		paused = true;

		if (check != null)
			handler.removeCallbacks(check);

		handler.postDelayed(check = new Runnable() {
			@Override
			public void run() {
				if (foreground && paused) {
					foreground = false;
					bit6.onBackground();
				}
			}
		}, CHECK_DELAY);
	}
}
