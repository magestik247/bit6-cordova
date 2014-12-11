package com.bit6.sdk;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;

import com.bit6.sdk.Bit6;

/**
 * Bit6 Cordova plugin
 */
public class Bit6Plugin extends CordovaPlugin {

    static final String REGISTER = "register";

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals(REGISTER)) {
            register(args.getString(0));
            return true;
        }
        return false;
    }

    void register(String gcmSenderId) {
       Context context= this.cordova.getActivity().getApplicationContext();

       int appResId = cordova.getActivity().getResources().getIdentifier("api_key", "string", cordova.getActivity().getPackageName());
       String apikey = cordova.getActivity().getString(appResId);

       Bit6.getInstance().init(context, apikey, null, gcmSenderId);
    }
}
