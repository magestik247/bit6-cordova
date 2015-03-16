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

//so far just keeping chatter's name. This may require changing to uri format used in JS sdk (usr:someUser)
var currentChatUri = "";
var lastTypingSent = 0;

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
    },

    // deviceready Event Handler
    //
    // The scope of 'this' is the event. In order to call the 'receivedEvent'
    // function, we must explicitly call 'app.receivedEvent(...);'
    onDeviceReady: function() {
      //alert("Device READY");

      initButtonListeners();

      bit6.isAuthenticated(
        function(response){
          console.log(response);
          if (response.connected)
           onLoginDone();
        },
        function(error){
          alert("Error on isAuthenticated api call");
      });

       //adding notification callbacks
       bit6.on('messageReceived', onMessageReceived);
       bit6.on('typingStarted', onTypingStarted);
       bit6.on('typingStopped', onTypingStopped);
      },
  };

function onMessageReceived() {
   if (currentChatUri)
    updateCurrentChat();
   updateConversations();
};

function onTypingStarted() {
  $("#typingLabel")[0].innerHTML = "Typing...";
}

function onTypingStopped() {
  $("#typingLabel")[0].innerHTML = "";
}

function updateCurrentChat() {
  bit6.getConversationByUri(currentChatUri,
    function(conversation){
      populateConversationWindow(conversation);
    },
    function(error){
      alert("Error on getConversationByUri api call");
    });
}

function populateConversationWindow(conversation) {
  var messages = conversation.messages;
  $("#incoming").html("");

  for(var index = 0; index < messages.length;index++){
    var div = $("<div/>");
    var displayName = conversation.title;
    if (!messages[index].incoming){
      displayName = "Me";
    }
    div.append("<h3>" + displayName + "</h3>");
    div.append("<p>" + messages[index].content + "</p>");
    $("#incoming").append($(div).html());
  }
  //scroll to bottom
  $("#incoming").scrollTop($("#incoming")[0].scrollHeight);
}

function onLoginDone() {
  switchToChatListScreen();
   updateConversations();
}

function updateConversations() {
  bit6.conversations(
    function(data){
      var listToDisplay = "Convsersatioins: \n ";
      for (var i = 0; i < data.conversations.length; ++i) {
        console.log(data.conversations[i].displayName);
        listToDisplay = listToDisplay.concat(data.conversations[i].displayName).concat("\n");
        populateChatList(data.conversations);
      }
    },
    function(error){
      alert("Error on getting conv" + error);
    });
}

function initButtonListeners() {
  $("#signup").click(function(){
    bit6.signup($("#username").val(), $("#password").val(), function(success){
      var result = JSON.stringify(success);
      if (result.indexOf("userid") > -1)
        alert("Signed Up!");
      else
        alert(result);
    }
    , function(error){
      alert("Error:" + JSON.stringify(error));
    });
  });

  $("#login").click(function(){
   //bit6.logout();

   bit6.login($("#username").val(), $("#password").val(), function(success){
     console.log(JSON.stringify(success));
     switchToChatListScreen();
   }, function(error){
     alert("Error: " + JSON.stringify(error));
   });
 });

  $("#voiceCall").click(function(){
   var opts = { video : false};
       //FIXME: get current username
       bit6.startCall(currentChatUri, opts, function(success){
         console.log(JSON.stringify(success));
       }, function(error){
         alert("Error on call" + JSON.stringify(error));
       });
     });

  $("#videoCall").click(function(){
   var opts = { video : true};
       //FIXME: get current username
       bit6.startCall(currentChatUri, opts, function(success){
         console.log(JSON.stringify(success));
       }, function(error){
         alert("Error on call" + JSON.stringify(error));
       });
     });

   $("#sendMessage").click(function(){

    bit6.sendTextMessage($("#message").val(), currentChatUri, function(success){
      //console.log(JSON.stringify(success));
      onMessageReceived();
    }, function(error){
      alert(JSON.stringify(error));
    });

    $("#message").val("");
  });

   $("#logout").click(function(){
       bit6.logout(function(success){
        switchToLoginScreen();
     }, function(error){
       alert(JSON.stringify(error));
     });
  });

    // Key down event in compose input field
    $('#message').keydown(function() {
        var now = Date.now();
        if (now - lastTypingSent > 7000) {
            lastTypingSent = now;
            bit6.sendTypingNotification(currentChatUri);
        }
    });
 }

function populateChatList(conversations) {

var chatList = $('#chatListScreen').html('');
for(var i=0; i < conversations.length; i++) {
  var c = conversations[i];
  if (!currentChatUri) {
    currentChatUri = c.uri;
  }
  var latestText = c.content;

  var d = new Date(Number(c.stamp));
  var stamp = d.toLocaleDateString() + ' ' + d.toLocaleTimeString();

  chatList.append(
    $('<div />')
    .append($('<strong>' + c.title + '</strong>'))
    .append($('<span>' + latestText + '</span>'))
    .append($('<em>' + stamp + '</em>'))
    .on('click', {'name': c.title}, function(e) {
      onChatSelected(e.data.name);
    })
    );
}
}

function onChatSelected(name) {
  switchToChatScreen();
  $("#chatter")[0].innerHTML = name;
  currentChatUri = name;
  updateCurrentChat();
}

function switchToChatScreen() {
  $("#loginScreen")[0].style.display = "none";
  $("#chatScreen")[0].style.display = "block";
  $("#chatListScreen")[0].style.display = "none";
}

function switchToChatListScreen() {
  $("#loginScreen")[0].style.display = "none";
  $("#chatScreen")[0].style.display = "none";
  $("#chatListScreen")[0].style.display = "block";
}

function switchToLoginScreen() {
  $("#loginScreen")[0].style.display = "block";
  $("#chatScreen")[0].style.display = "none";
  $("#chatListScreen")[0].style.display = "none";
}