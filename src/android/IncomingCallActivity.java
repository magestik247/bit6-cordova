package com.bit6.sdk.plugin;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.TextView;
import android.os.Handler;

import com.bit6.sdk.Bit6;
import com.bit6.sdk.Ringer;
import com.bit6.sdk.RtcDialog;
import	android.util.Log;

import com.bit6.sdk.plugin.LifecycleHelper;


import java.lang.ClassLoader;


public class IncomingCallActivity extends Activity implements RtcDialog.StateListener, OnClickListener {

	private RtcDialog dialog;
	private Button answer, reject;
	private Ringer ringer;
	private Bit6 bit6;

	@Override
	protected void onCreate(Bundle savedInstanceState) {

		super.onCreate(savedInstanceState);

        //Loading resources at runtime to not hardcode the app package name (since the R.java is generated in app package)
		String appPackage = getApplicationContext().getPackageName();
        ClassLoader classLoader = getApplicationContext().getClassLoader();
        int activity_incoming_call_layout = 0;
        int incoming_video_call= 0;
        int incoming_voice_call= 0;
        int user_is_calling= 0;
        int id_message= 0;
        int id_answer= 0;
        int id_reject= 0;
        int id_title= 0;

        try {
            Class layout = classLoader.loadClass(appPackage + ".R$layout");
            activity_incoming_call_layout = layout.getField("activity_incoming_call").getInt(null);

            Class strings = classLoader.loadClass(appPackage + ".R$string");
            incoming_video_call = strings.getField("incoming_video_call").getInt(null);
            incoming_voice_call = strings.getField("incoming_voice_call").getInt(null);
            user_is_calling = strings.getField("user_is_calling").getInt(null);

            Class ids = classLoader.loadClass(appPackage + ".R$id");
            id_message = ids.getField("message").getInt(null);
            id_answer = ids.getField("answer").getInt(null);
            id_reject = ids.getField("reject").getInt(null);
            id_title = ids.getField("title").getInt(null);
        }
        catch(ClassNotFoundException ex) {
            Log.e("Bit6 PLUGIN", ex.toString());
        }
        catch (IllegalAccessException ex) {
            Log.e("Bit6 PLUGIN", ex.toString());
        }
        catch (NoSuchFieldException ex) {
            Log.e("Bit6 PLUGIN", ex.toString());
        }


        setContentView(activity_incoming_call_layout);

		int flags = WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
				| WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
				| WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON;

		getWindow().setFlags(flags, flags);

		ringer = new Ringer(this);
		bit6 = Bit6.getInstance();

		dialog = bit6.getDialogFromIntent(getIntent());

		dialog.addStateListener(this);

		TextView title = (TextView) findViewById(id_title);
		//title.setText(dialog.hasVideo() ? R.string.incoming_video_call : R.string.incoming_voice_call);
		title.setText(dialog.hasVideo() ? incoming_video_call : incoming_voice_call);

		String other = dialog.getOther();

		String callerName = other.toString().substring(
				other.toString().indexOf(":") + 1);

		String msg = String.format(getString(user_is_calling),
				callerName);

		TextView message = (TextView) findViewById(id_message);
		message.setText(msg);

		answer = (Button) findViewById(id_answer);
		reject = (Button) findViewById(id_reject);

		answer.setOnClickListener(this);
		reject.setOnClickListener(this);
	}

	@Override
	protected void onStart() {
		super.onStart();
		ringer.playRinging();
	}

	@Override
	protected void onStop() {
		ringer.stop();
		super.onStop();
	}

	@Override
	protected void onDestroy() {
		dialog.removeStateListener(this);
		super.onDestroy();
	}

	@Override
	public void onClick(View v) {
		if (v == answer) {
			ringer.stop();
			// Launch default InCall Activity
			 dialog.launchInCallActivity(this);

			// // Launch custom InCall Activity
			// Intent intent = new Intent(this, CallActivity.class);
			// intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
			// dialog.setAsIntentExtra(intent);
			// startActivity(intent);

			//finish();
		}
		else if (v == reject) {
			ringer.stop();
			dialog.hangup();
			finish();
		}
	}

	@Override
	public void onStateChanged(RtcDialog d, int state) {
		if (state == RtcDialog.END) {
			finish();
		}
	}

	//@Override
    // public void onPause() {
    //    super.onPause();
    //    LifecycleHelper.getInstance().onBackground();
    // }

    @Override
    public void onResume() {
       super.onResume();
       LifecycleHelper.getInstance().onForeground();
    }
}