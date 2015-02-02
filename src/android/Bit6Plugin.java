package com.bit6.sdk;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;

import com.bit6.sdk.Address;
import com.bit6.sdk.Bit6;
import com.bit6.sdk.ResultCallback;
import com.bit6.sdk.Message;
import com.bit6.sdk.Message.Messages;
import com.bit6.sdk.RtcDialog;
import com.bit6.sdk.MessageStatusListener;

import android.database.Cursor;


/**
 * Bit6 Cordova plugin
 */
public class Bit6Plugin extends CordovaPlugin {

  static final String INIT = "init";
  static final String LOGIN = "login";
  static final String GET_CONVERSATIONS = "conversations";
  static final String GET_CONVERSATION = "getConversation";
  static final String IS_CONNECTED = "isConnected";
  static final String START_CALL = "startCallToAddress";
  static final String SEND_MESSAGE = "sendMessage";
  static final String START_LISTENING = "startListening";


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

 CallbackContext mNotificationCallback;

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

 void startCall(String other, Boolean isVideo, final CallbackContext callbackContext) {

  Address to = Address.parse(other);

  RtcDialog dialog = Bit6.getInstance().startCall(to, isVideo);
  // Launch the default InCall activity
  Context context= this.cordova.getActivity().getApplicationContext();
  dialog.launchInCallActivity(context);
}

void sendMessage(String message, String other, final CallbackContext callbackContext) {
  Address to = Address.parse(other);

  Message m =  Message.newMessage(to).text(message);
  // Bit6.getInstance().sendMessage(m, new MessageStatusListener() {
  //   @Override
  //   public void onMessageStatusChanged(Message msg, int state) {
  //   if (state == Message.STATUS_SENDING) {
  //     callbackContext.success();
  //   } else if (state == Message.STATUS_FAILED) {
  //      callbackContext.error("Error on message sending");
  //   }
  // }
  // });
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

void conversations(final CallbackContext callbackContext){
  try {
   JSONArray conversations = new JSONArray();
   Cursor cursor;
   cursor = Bit6.getInstance().getConversations();

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
}

void notify(final String notificationName) {
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
}
}
