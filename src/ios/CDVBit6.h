#import <Cordova/CDV.h>
#import <Bit6SDK/Bit6SDK.h>

@interface CDVBit6 : CDVPlugin

- (void)signup:(CDVInvokedUrlCommand*)command;
- (void)login:(CDVInvokedUrlCommand*)command;
- (void)logout:(CDVInvokedUrlCommand*)command;
- (void)isAuthenticated:(CDVInvokedUrlCommand*)command;
- (void)startCallToAddress:(CDVInvokedUrlCommand*)command;
- (void)sendMessage:(CDVInvokedUrlCommand*)command;
- (void)sendTypingNotification:(CDVInvokedUrlCommand*)command;
- (void)conversations:(CDVInvokedUrlCommand*)command;
- (void)getConversationByUri:(CDVInvokedUrlCommand*)command;

- (void)startListening:(CDVInvokedUrlCommand*)command;
- (void)stopListen:(CDVInvokedUrlCommand*)command;

@property (strong) NSString* callbackId;

@end
