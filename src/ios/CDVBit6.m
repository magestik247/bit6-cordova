#import "CDVBit6.h"

@implementation CDVBit6

@synthesize callbackId;

- (void)signup:(CDVInvokedUrlCommand *)command
{
    NSString *username = [command.arguments objectAtIndex:0];
    NSString *password = [command.arguments objectAtIndex:1];


    Bit6Address *identity = [Bit6Address addressWithKind:Bit6AddressKind_USERNAME value:username];

    [Bit6Session signUpWithUserIdentity:identity password:password completionHandler:^(NSDictionary *response, NSError *error) {
         [self processCommandWithResult:command response:response error:error];
    }];
}

- (void)login:(CDVInvokedUrlCommand *)command
{
    NSString *username = [command.arguments objectAtIndex:0];
    NSString *password = [command.arguments objectAtIndex:1];

    Bit6Address *identity = [Bit6Address addressWithKind:Bit6AddressKind_USERNAME value:username];

    [Bit6Session loginWithUserIdentity:identity password:password completionHandler:^(NSDictionary *response, NSError *error) {
        [self processCommandWithResult:command response:response error:error];
    }];
}

- (void)logout:(CDVInvokedUrlCommand*)command
{
    [Bit6Session logoutWithCompletionHandler:^(NSDictionary *response, NSError *error) {
        [self processCommandWithResult:command response:response error:error];
    }];
}

- (void)isConnected:(CDVInvokedUrlCommand*)command
{
    if ([Bit6Session isConnected])
        [self processCommandWithResult:command response:[NSDictionary dictionaryWithObjectsAndKeys:@(YES), @"connected", nil] error:nil];
    else
        [self processCommandWithResult:command response:[NSDictionary dictionaryWithObjectsAndKeys:@(NO), @"connected", nil] error:nil];
}

- (void)conversations:(CDVInvokedUrlCommand*)command
{
   //self.callbackId = command.callbackId;
   NSArray *conversations = [Bit6 conversations];

    if ([conversations count]){

        NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:[conversations count]];

        for (Bit6Conversation * convers in conversations){
            NSLog(@"processing conv- %@", convers.displayName);
            NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];

            NSMutableArray *messages = [self bit6ArrayToDictionaryArray:[convers.messages mutableCopy]];

            //TODO: Include all needed data
            [mutableDictionary setObject:convers.displayName forKey:@"title"];
            //[mutableDictionary setObject:convers.address. forKey:@"uri"];
            [mutableDictionary setObject:messages forKey:@"messages"];

            [mutableArray addObject:mutableDictionary];
        }

        NSDictionary *data = [NSDictionary dictionaryWithObject:mutableArray forKey:@"conversations"];


        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
        [result setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
}


- (void)startCallToAddress:(CDVInvokedUrlCommand*)command
{
    NSString *to = [command.arguments objectAtIndex:0];
    //TOOD: Should support all kinds, not only username.
    Bit6Address *address = [Bit6Address addressWithKind:Bit6AddressKind_USERNAME value:to];
    BOOL hasVideo = [[command.arguments objectAtIndex:1] boolValue];
    [Bit6 startCallToAddress:address hasVideo:hasVideo];
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

- (void)startListening:(CDVInvokedUrlCommand*)command
{
    self.callbackId = command.callbackId;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(conversationsUpdatedNotification:) name:Bit6ConversationsUpdatedNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messagesUpdatedNotification:) name:Bit6MessagesUpdatedNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(typingDidBeginRtNotification:) name:Bit6TypingDidBeginRtNotification object:nil];
}

- (void) messagesUpdatedNotification:(NSNotification*)notification
{
    NSLog(@"Info: Received messagesUpdatedNotification");
}

- (void) typingDidBeginRtNotification:(NSNotification*)notification
{
    NSLog(@"Info: Received Typing Notification");
}


- (void) conversationsUpdatedNotification:(NSNotification*)notification
{
   //get updated conversations
   NSArray *messages = [Bit6 messagesWithOffset:0 length:NSIntegerMax asc:NO];

    if ([messages count]){

        NSMutableArray *mutableArray = [self bit6ArrayToDictionaryArray:messages];
        NSDictionary *data = [NSDictionary dictionaryWithObject:mutableArray forKey:@"messages"];

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



//This is a supporting function which allows to get NSArray of dictionaries from Bit6Messages.
- (NSArray*) bit6ArrayToDictionaryArray:(NSArray*) messages
{
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:[messages count]];

    for (Bit6Message * message in messages){

        NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];

        [mutableDictionary setObject:message.content forKey:@"content"];
        [mutableDictionary setObject:@(message.incoming) forKey:@"incoming"];
        [mutableDictionary setObject:[[NSDictionary alloc] initWithObjectsAndKeys:message.other.displayName, @"displayName", nil]  forKey:@"other"];
        [mutableDictionary setObject:[[NSDictionary alloc] initWithObjectsAndKeys:message.data.lat, @"lat", message.data.lng, @"lng", nil]  forKey:@"data"];

        [mutableArray addObject:mutableDictionary];
    }

    return mutableArray;
}

@end

