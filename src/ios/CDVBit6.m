#import "CDVBit6.h"

@implementation CDVBit6

@synthesize callbackId;

- (void)signup:(CDVInvokedUrlCommand *)command
{
    NSString *username = [command.arguments objectAtIndex:0];
    NSString *password = [command.arguments objectAtIndex:1];


    Bit6Address *identity = [Bit6Address addressWithKind:Bit6AddressKind_USERNAME value:username];

    [Bit6.session signUpWithUserIdentity:identity password:password completionHandler:^(NSDictionary *response, NSError *error) {
       [self processCommandWithResult:command response:response error:error];
   }];
}

- (void)login:(CDVInvokedUrlCommand *)command
{
    NSString *username = [command.arguments objectAtIndex:0];
    NSString *password = [command.arguments objectAtIndex:1];

    Bit6Address *identity = [Bit6Address addressWithKind:Bit6AddressKind_USERNAME value:username];

    [Bit6.session loginWithUserIdentity:identity password:password completionHandler:^(NSDictionary *response, NSError *error) {
        [self processCommandWithResult:command response:response error:error];
    }];
}

- (void)logout:(CDVInvokedUrlCommand*)command
{
    [Bit6.session logoutWithCompletionHandler:^(NSDictionary *response, NSError *error) {
        [self processCommandWithResult:command response:response error:error];
    }];
}

- (void)isAuthenticated:(CDVInvokedUrlCommand*)command
{
    if (Bit6.session.authenticated)
        [self processCommandWithResult:command response:[NSDictionary dictionaryWithObjectsAndKeys:@(YES), @"connected", nil] error:nil];
    else
        [self processCommandWithResult:command response:[NSDictionary dictionaryWithObjectsAndKeys:@(NO), @"connected", nil] error:nil];
}

- (void)conversations:(CDVInvokedUrlCommand*)command
{

 NSArray *bit6Conversations = [Bit6 conversations];

 if ([bit6Conversations count]){
    NSMutableArray *conversations = [[NSMutableArray alloc] initWithCapacity:[bit6Conversations count]];

    for (Bit6Conversation * convers in bit6Conversations){
        NSMutableDictionary *convDictionary = [[NSMutableDictionary alloc] init];

        NSArray *messages = [self bit6MsgArrayToDictionaryArray:convers.messages];

            //TODO: Include all needed data
        [convDictionary setObject:convers.displayName forKey:@"title"];
            //[mutableDictionary setObject:convers.address. forKey:@"uri"];
        [convDictionary setObject:messages forKey:@"messages"];

        [conversations addObject:convDictionary];
    }

    NSDictionary *data = [NSDictionary dictionaryWithObject:conversations forKey:@"conversations"];

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}
}


- (void)getConversationByUri:(CDVInvokedUrlCommand*)command
{
 NSString *uri = [command.arguments objectAtIndex:0];
 NSArray *bit6Conversations = [Bit6 conversations];
 if ([bit6Conversations count]){
    for (Bit6Conversation * convers in bit6Conversations){
        if ([convers.address.displayName isEqualToString:uri]) {
            NSMutableDictionary *convDictionary = [[NSMutableDictionary alloc] init];
            NSArray *messages = [self bit6MsgArrayToDictionaryArray:convers.messages];

                //TODO: Include all needed data
            [convDictionary setObject:convers.displayName forKey:@"title"];
            [convDictionary setObject:messages forKey:@"messages"];

            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:convDictionary];
            [result setKeepCallbackAsBool:YES];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            break;
        }
    }
}
}

- (void)startCallToAddress:(CDVInvokedUrlCommand*)command
{

    NSString *to = [command.arguments objectAtIndex:0];
    //TOOD: Should support all kinds, not only username.
    Bit6Address *address = [Bit6Address addressWithKind:Bit6AddressKind_USERNAME value:to];
    BOOL hasVideo = [[command.arguments objectAtIndex:1] boolValue];
    Bit6CallController *callController = [Bit6 startCallToAddress:address hasVideo:hasVideo];
    //UIViewController *vc = nil; //create a custom viewcontroller or nil to use the default one

    Bit6CallViewController *callVC = [Bit6CallViewController createDefaultCallViewController];

    if (callController){


         [callController addObserver:self forKeyPath:@"callState" options:NSKeyValueObservingOptionOld context:NULL];

        //use a custom in-call UIViewController
        //MyCallViewController *callVC = [[MyCallViewController alloc] init];

        //start the call
        [callController connectToViewController:callVC];

    }
    else {
        NSLog(@"Call failed");
    }
}

- (void)sendMessage:(CDVInvokedUrlCommand*)command
{
    NSString *message = [command.arguments objectAtIndex:0];
    NSString *to = [command.arguments objectAtIndex:1];

    Bit6OutgoingMessage *bit6Message = [Bit6OutgoingMessage new];

    bit6Message.content = message;

    Bit6MessageChannel channel = (Bit6MessageChannel)[command.arguments objectAtIndex:2];

    bit6Message.destination = [Bit6Address addressWithKind:Bit6AddressKind_USERNAME value:to];
    bit6Message.channel = channel;

    [bit6Message sendWithCompletionHandler:^(NSDictionary *response, NSError *error) {
        [self processCommandWithResult:command response:response error:error];
    }];
}

- (void)sendTypingNotification:(CDVInvokedUrlCommand*)command
{
    NSString *to = [command.arguments objectAtIndex:0];
    Bit6Address *address = [Bit6Address addressWithKind:Bit6AddressKind_USERNAME value:to];

    [Bit6 typingBeginToAddress:address];
}


- (void)startListening:(CDVInvokedUrlCommand*)command
{
    self.callbackId = command.callbackId;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(conversationsUpdatedNotification:) name:Bit6ConversationsUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messagesUpdatedNotification:) name:Bit6MessagesUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(typingDidBeginRtNotification:) name:Bit6TypingDidBeginRtNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(typingDidEndRtNotification:) name:Bit6TypingDidEndRtNotification object:nil];
}

- (void) messagesUpdatedNotification:(NSNotification*)notification
{
    NSDictionary *data = [NSDictionary dictionaryWithObject:@"messageReceived" forKey:@"notification"];

    if (self.callbackId) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
        [result setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    }
}

- (void) typingDidBeginRtNotification:(NSNotification*)notification
{
    NSLog(@"Info: Received Typing did begin begin Notification");
    NSDictionary *data = [NSDictionary dictionaryWithObject:@"typingStarted" forKey:@"notification"];

    if (self.callbackId) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
        [result setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    }
}

- (void) typingDidEndRtNotification:(NSNotification*)notification
{
    NSLog(@"Info: Received Typing did end Notification");
    NSDictionary *data = [NSDictionary dictionaryWithObject:@"typingStopped" forKey:@"notification"];

    if (self.callbackId) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
        [result setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    }
}


//TODO: This handler actually gets messages, not conversations. The logic should be moved to a better place
- (void) conversationsUpdatedNotification:(NSNotification*)notification
{
   //get updated conversations
 NSArray *bit6Messages = [Bit6 messagesWithOffset:0 length:NSIntegerMax asc:NO];

 if ([bit6Messages count]){

        //NSArray *messages = [self bit6MsgArrayToDictionaryArray:bit6Messages];
        //NSDictionary *data = [NSDictionary dictionaryWithObject:messages forKey:@"messages"];
    NSDictionary *data = [NSDictionary dictionaryWithObject:@"messageReceived" forKey:@"notification"];

    if (self.callbackId) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
        [result setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    }
}
}

- (void)stopListen:(CDVInvokedUrlCommand*)command
{
    self.callbackId = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:Bit6ConversationsUpdatedNotification object:nil];
}


- (void)processCommandWithResult:(CDVInvokedUrlCommand*)command response:(NSDictionary*)response error:(NSError*)error

{
    CDVPluginResult* pluginResult = nil;
    if (!error)
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
    else
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:response];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    });
}



//This is a supporting function which returns NSArray of dictionaries from Bit6Messages.
- (NSArray*) bit6MsgArrayToDictionaryArray:(NSArray*) messages
{
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:[messages count]];

    for (Bit6Message * message in messages){

        NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];

        [mutableDictionary setObject:message.content forKey:@"content"];
        [mutableDictionary setObject:@(message.incoming) forKey:@"incoming"];
        [mutableDictionary setObject:(message.updated ? message.updated : [NSNumber numberWithInt:0]) forKey:@"updated"];
        [mutableDictionary setObject:[[NSDictionary alloc] initWithObjectsAndKeys:message.other.displayName, @"displayName", nil]  forKey:@"other"];
        [mutableDictionary setObject:[[NSDictionary alloc] initWithObjectsAndKeys:message.data.lat, @"lat", message.data.lng, @"lng", nil]  forKey:@"data"];

        [mutableArray addObject:mutableDictionary];
    }

    return mutableArray;
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isKindOfClass:[Bit6CallController class]]) {
        if ([keyPath isEqualToString:@"callState"]) {
            [self callStateChangedNotification:object];
        }
    }
}

- (void) callStateChangedNotification:(Bit6CallController*)callController
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //the call is starting: show the viewController
        if (callController.callState == Bit6CallState_PROGRESS) {
            [Bit6 presentCallController:callController];
        }
        //the call ended: remove the observer and dismiss the viewController
        else if (callController.callState == Bit6CallState_END) {
            [callController removeObserver:self forKeyPath:@"callState"];
            [Bit6 dismissCallController:callController];
        }
        //the call ended with an error: remove the observer and dismiss the viewController
        else if (callController.callState == Bit6CallState_ERROR) {
            [callController removeObserver:self forKeyPath:@"callState"];
            [Bit6 dismissCallController:callController];
            [[[UIAlertView alloc] initWithTitle:@"An Error Occurred" message:callController.error.localizedDescription?:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    });
}


@end

