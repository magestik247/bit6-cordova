/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
var app = {
    // Application Constructor

    //cordova plugins add ~/Source/Telerik/Plugins/Bit6/Plugin/ --variable API_KEY=308x-3bnqo

    initialize: function() {
        this.bindEvents();
    },
    // Bind Event Listeners
    //
    // Bind any events that are required on startup. Common events are:
    // 'load', 'deviceready', 'offline', and 'online'.
    bindEvents: function() {
        document.addEventListener('deviceready', this.onDeviceReady, false);
        document.addEventListener('messageReceived', this.onMessageReceived, false);
    },

    // deviceready Event Handler
    //
    // The scope of 'this' is the event. In order to call the 'receivedEvent'
    // function, we must explicitly call 'app.receivedEvent(...);'
    onDeviceReady: function() {
        alert("Device READY");
        $("#signup").click(function(){
            bit6.register($("#username").val(), $("#password").val(), function(success){
                alert("Success:" + JSON.stringify(success));
            }
            , function(error){
              alert("Error:" + JSON.stringify(error));
            });
        });

        $("#login").click(function(){
           bit6.logout();

           bit6.login($("#username").val(), $("#password").val(), function(success){
               console.log(JSON.stringify(success));
               switchToChatScreen();
           }, function(error){
             alert("Error: " + JSON.stringify(error));
           });
        });

        $("#voiceCall").click(function(){
           var opts = { video : false};
           //FIXME: get current username
           bit6.startCall("nar2", opts, function(success){
               console.log(JSON.stringify(success));
           }, function(error){
             alert("Error on call" + JSON.stringify(error));
           });
        });

        $("#videoCall").click(function(){
           var opts = { video : true};
           //FIXME: get current username
           bit6.startCall("nar2", opts, function(success){
               console.log(JSON.stringify(success));
           }, function(error){
             alert("Error on call" + JSON.stringify(error));
           });
        });



        $("#sendMessage").click(function(){
            bit6.sendPushMessage($("#message").val(), "nar2", function(success){
              console.log(JSON.stringify(success));
            }, function(error){
              alert(JSON.stringify(error));
            });
        });

    },
    onMessageReceived : function(e){
      $("#incoming").html("");

      for(var index = 0; index < e.messages.length;index++){
            var div = $("<div/>");
            var displayName = e.messages[index].other.displayName;
            if (!e.messages[index].incoming){
              displayName = "Me";
            }

            div.append("<h3>" + displayName + "</h3>");
            div.append("<p>" + e.messages[index].content + "</p>");
            $("#incoming").append($(div).html());
        }
    }
};

function switchToChatScreen() {
  var loginScreen = $("#loginScreen")[0];
  loginScreen.style.display = "none";
  var chatScreen = $("#chatScreen")[0];
  chatScreen.style.display = "block";
}
