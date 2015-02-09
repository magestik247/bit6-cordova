package com.bit6.ChatDemo;

import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;


public class IncomingMessageReceiver extends BroadcastReceiver {

	@Override
	public void onReceive(Context context, Intent intent) {
		//Nothing to do for now.
		// if(intent.getExtras() != null){
		// 	String content = intent.getExtras().getString("content");
		// 	String senderName = intent.getExtras().getString("senderName");
		// 	sendNotification(context, content, senderName);
		// }
	}
}