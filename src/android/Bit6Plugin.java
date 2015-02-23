package com.bit6.ChatDemo;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.BroadcastReceiver;
import android.content.IntentFilter;
import android.widget.CursorAdapter;
import android.view.View;
import android.view.ViewGroup;
import android.database.Cursor;
import android.util.Log;
import android.os.Bundle;


import com.bit6.sdk.Address;
import com.bit6.sdk.Bit6;
import com.bit6.sdk.ResultCallback;
import com.bit6.sdk.Message;
import com.bit6.sdk.Message.Messages;
import com.bit6.sdk.RtcDialog;
import com.bit6.sdk.MessageStatusListener;
import com.bit6.sdk.RtNotificationListener;

import com.bit6.ChatDemo.IncomingCallActivity;


/**
 * Bit6 Cordova plugin
 */
public class Bit6Plugin extends CordovaPlugin {

  static final String INIT = "init";
  static final String LOGIN = "login";
  static final String LOGOUT = "logout";
  static final String SIGNUP = "signup";
  static final String GET_CONVERSATIONS = "conversations";
  static final String GET_CONVERSATION = "getConversation";
  static final String IS_CONNECTED = "isConnected";
  static final String START_CALL = "startCallToAddress";
  static final String SEND_MESSAGE = "sendMessage";
  static final String SEND_TYPING_NOTIFICATION = "sendTypingNotification";
  static final String START_LISTENING = "startListening";



  MessageCursorAdapter mConvCursorAdapter;
  MessageCursorAdapter mMessageCursorAdapter;
  CallbackContext mNotificationCallback;


  class MessageCursorAdapter extends CursorAdapter {
   MessageCursorAdapter (Context context, Cursor c, boolean autoRequery) {
    super(context, c, autoRequery);
  }

  @Override
  protected void onContentChanged() {
    sendNotification("messageReceived");
  }

  @Override
  public void  bindView(View v, Context cntx, Cursor c) {}
  public View newView(Context cntx, Cursor c, ViewGroup vg) { return null; }
}

class IncomingCallReceiver extends BroadcastReceiver{

  @Override
  public void onReceive(Context context, Intent intent) {
   Intent i = new Intent(context, IncomingCallActivity.class);
   i.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
   i.putExtra(Bit6.INTENT_EXTRA_DIALOG, intent.getBundleExtra(Bit6.INTENT_EXTRA_DIALOG));
   context.startActivity(i);
 }
}

@Override
public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

 if (action.equals(INIT)) {
  init();
  callbackContext.success();
  return true;
}
if (action.equals(LOGIN)) {
 login(args.getString(0), args.getString(1), callbackContext);
 return true;
}
if (action.equals(LOGOUT)) {
 logout(callbackContext);
 return true;
}
if (action.equals(SIGNUP)) {
 signup(args.getString(0), args.getString(1), callbackContext);
 return true;
}
if (action.equals(GET_CONVERSATIONS)) {
 getConversations(callbackContext);
 return true;
}
if (action.equals(GET_CONVERSATION)) {
 getConversation(args.getString(0), callbackContext);
 return true;
}
if (action.equals(START_CALL)) {
 startCall(args.getString(0), args.getBoolean(1), callbackContext);
 return true;
}
if (action.equals(SEND_MESSAGE)) {
 sendMessage(args.getString(0), args.getString(1), callbackContext);
 return true;
}
if (action.equals(SEND_TYPING_NOTIFICATION)) {
 sendTypingNotification(args.getString(0));
 return true;
}
if (action.equals(START_LISTENING)) {
 startListening(callbackContext);
 return true;
}
if (action.equals(IS_CONNECTED)) {
 isConnected(callbackContext);
 return true;
}

return false;
}

@Override
public void onPause(boolean multitasking) {
       //TODO: This needs to be fixed (requires some changes in sdk).
       //Commented out to make IncomingCallActivity/InCallScreen work, otherwise the connection is being lost
       //Bit6.getInstance().onBackground();
}
@Override
public void onResume(boolean multitasking) {
 Bit6.getInstance().onForeground();
}


void login(String username, String pass, final CallbackContext callbackContext) {
  Address identity = Address.fromParts(Address.KIND_USERNAME, username);

  Bit6.getInstance().login(identity, pass, new ResultCallback() {
    @Override
    public void onResult(boolean success, String msg) {
      if (success) {
        callbackContext.success(msg);
      }
      else {
        callbackContext.error(msg);
      }
    }
  });
}

void logout(final CallbackContext callbackContext) {
  Bit6.getInstance().logout();
  //No callabck here, so just returning success
  callbackContext.success("");
}

void signup(String username, String pass, final CallbackContext callbackContext) {
  Address identity = Address.fromParts(Address.KIND_USERNAME, username);

  Bit6.getInstance().signup(identity, pass, new ResultCallback() {
    @Override
    public void onResult(boolean success, String msg) {
      if (success) {
        callbackContext.success(msg);
      }
      else {
        callbackContext.error(msg);
      }
    }
  });
}

void startCall(String other, final Boolean isVideo, final CallbackContext callbackContext) {

  Bit6.getInstance().onForeground();
  Address to = Address.parse(other);
  final RtcDialog dialog = Bit6.getInstance().startCall(to, isVideo);
   // Launch the default InCall activity
  final Context context= this.cordova.getActivity().getApplicationContext();
  dialog.launchInCallActivity(context);
}

//No callback for this case. Can be added later if needed.
void sendTypingNotification(String dest) {
  Bit6.getInstance().sendTypingNotification(Address.parse(dest));
}

void sendMessage(String message, String other, final CallbackContext callbackContext) {
  Address to = Address.parse(other);
  Message m =  Message.newMessage(to).text(message);

  Bit6.getInstance().sendMessage(m, new MessageStatusListener() {
    @Override
    public void onMessageStatusChanged(Message msg, int state) {
      if (state == Message.STATUS_FAILED) {
       callbackContext.error("Error on message sending");
     }
     else {
      //Fix: There is redundancy in callbacks for this case
      // CursorAdapter notifies too.
      callbackContext.success(state);
    }
  }
  @Override
  public void onResult(boolean b,  String s) { }
});
}

void getConversation(String other, final CallbackContext callbackContext){
  JSONArray messages = new JSONArray();
  Address address = Address.parse(other);
  Cursor cursor;

  cursor = Bit6.getInstance().getConversation(address);

  try {
   while (cursor.moveToNext()) {
     JSONObject item = new JSONObject();
     String content = cursor.getString(cursor.getColumnIndex(Messages.CONTENT));
     int flags = cursor.getInt(cursor.getColumnIndex(Messages.FLAGS));

     item.put("content", content);
     item.put("incoming", Message.isIncoming(flags));
     messages.put(item);
   }
   JSONObject data = new JSONObject();
   data.put("messages", messages);
   data.put("title", other.substring(other.indexOf(':') + 1));
   callbackContext.success(data);
 }
 catch (Exception e) {
  callbackContext.error("Error: " + e.getMessage());
}
}

void getConversations(final CallbackContext callbackContext){
  JSONArray conversations = new JSONArray();
  Cursor cursor;
  cursor = Bit6.getInstance().getConversations();

  try {
   while (cursor.moveToNext()) {
     JSONObject item = new JSONObject();
     String userName = cursor.getString(cursor.getColumnIndex(Messages.OTHER));
     String content = cursor.getString(cursor.getColumnIndex(Messages.CONTENT));
     String stamp = cursor.getString(cursor.getColumnIndex(Messages.CREATED));

     item.put("title", userName);
     item.put("content", content);
     item.put("stamp", stamp);
     conversations.put(item);
   }
   JSONObject data = new JSONObject();
   data.put("conversations", conversations);

   callbackContext.success(data);
 }
 catch (JSONException e) {
  callbackContext.error("Error: " + e.getMessage());
}
}

void initDBListeners() {
  Cursor cursor;
  cursor = Bit6.getInstance().getConversations();

  if(mConvCursorAdapter == null) {
    mConvCursorAdapter = new MessageCursorAdapter(this.cordova.getActivity().getApplicationContext(), cursor, false);
  }
}

void isConnected(final CallbackContext callbackContext) {
  try {
    JSONObject response = new JSONObject();
    response.put("connected", Bit6.getInstance().isAuthenticated());
    callbackContext.success(response);
  }
  catch (JSONException e) {
    callbackContext.error("Error: " + e.getMessage());
  }
}

void startListening(final CallbackContext callbackContext) {
  if (mNotificationCallback == null)
    mNotificationCallback = callbackContext;

  initDBListeners();

  Bit6.getInstance().addRtNotificationListener(new RtNotificationListener() {
    public void onTypingReceived(String from) {
        //Log.e("onTypingReceived()", from);
     sendNotification("typingStarted");
   }

   public void onNotificationReceived(String from, String type, JSONObject data) {
        //TODO
   }
 });
}

void sendNotification(final String notificationName) {
 if (mNotificationCallback == null)
   return; //TODO: Handle me

 JSONObject parameter = new JSONObject();
 try {
   parameter.put("notification", notificationName);

   PluginResult result = new PluginResult(PluginResult.Status.OK, parameter);
   result.setKeepCallback(true);
   mNotificationCallback.sendPluginResult(result);
 }
 catch (JSONException e) {
   //TODO: for this case this is not the best way to report the errors.
   mNotificationCallback.error("Error: " + e.getMessage());
 }
}


void init() {
 Context context= this.cordova.getActivity().getApplicationContext();

 int appResId = cordova.getActivity().getResources().getIdentifier("app_key", "string", cordova.getActivity().getPackageName());
 String apikey = cordova.getActivity().getString(appResId);

 Bit6.getInstance().init(context, apikey);

 IntentFilter i = new IntentFilter("com.bit6.ChatDemo.intent.INCOMING_CALL");
 this.cordova.getActivity().registerReceiver(new IncomingCallReceiver() , i);
}
}
