package com.bit6.sdk.plugin;


import android.content.Intent;
import android.content.BroadcastReceiver;
import android.content.Context;


import com.bit6.sdk.Bit6;
import com.bit6.sdk.RtcDialog;

import android.util.Log;

public class IncomingCallReceiver extends BroadcastReceiver{

  @Override
  public void onReceive(Context context, Intent intent) {
   Intent i = new Intent(context, IncomingCallActivity.class);
   Context c = context.getApplicationContext();
   i.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
   i.putExtra(Bit6.INTENT_EXTRA_DIALOG, intent.getBundleExtra(Bit6.INTENT_EXTRA_DIALOG));

   c.startActivity(i);
 }
}