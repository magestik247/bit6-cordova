package com.bit6.ChatDemo;

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

public class IncomingCallActivity extends Activity implements RtcDialog.StateListener, OnClickListener {

	private RtcDialog dialog;
	private Button answer, reject;
	private Ringer ringer;
	private Bit6 bit6;

	@Override
	protected void onCreate(Bundle savedInstanceState) {

		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_incoming_call);

		int flags = WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
				| WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
				| WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON;

		getWindow().setFlags(flags, flags);

		ringer = new Ringer(this);
		bit6 = Bit6.getInstance();

		dialog = bit6.getDialogFromIntent(getIntent());

		dialog.addStateListener(this);

		TextView title = (TextView) findViewById(R.id.title);
		title.setText(dialog.hasVideo() ? R.string.incoming_video_call : R.string.incoming_voice_call);

		String other = dialog.getOther();

		String callerName = other.toString().substring(
				other.toString().indexOf(":") + 1);

		String msg = String.format(getString(R.string.user_is_calling),
				callerName);

		TextView message = (TextView) findViewById(R.id.message);
		message.setText(msg);

		answer = (Button) findViewById(R.id.answer);
		reject = (Button) findViewById(R.id.reject);

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

			finish();
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

	// @Override
    public void onPause() {
       super.onPause();
       new Handler().postDelayed(new Runnable() {
			@Override
			public void run() {
				Bit6.getInstance().onBackground();
			}
		}, 5000);
    }

    @Override
    public void onResume() {
       super.onResume();
       Bit6.getInstance().onForeground();
    }
}