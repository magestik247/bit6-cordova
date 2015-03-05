#import "AppDelegate+bit6.h"
#import <Bit6SDK/Bit6SDK.h>
#import <objc/runtime.h>




@implementation AppDelegate (bit6)

 BOOL _handlingIncomingCall;


//This is used as workaround to not extend AppDelegate from Bit6ApplicatonManager
static Bit6ApplicationManager *appManager = nil;

- (id)getAppManager
{
    if (appManager == nil)
      appManager = [[Bit6ApplicationManager alloc] init];

    return appManager;
}


// its dangerous to override a method from within a category.
// Instead we will use method swizzling. we set this up in the load call.
+ (void)load
{
    Method original, swizzled;

    original = class_getInstanceMethod(self, @selector(init));
    swizzled = class_getInstanceMethod(self, @selector(swizzled_init));
    method_exchangeImplementations(original, swizzled);
}

- (AppDelegate *)swizzled_init
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createNotificationChecker:)
                                                 name:@"UIApplicationDidFinishLaunchingNotification" object:nil];

    // This actually calls the original init method over in AppDelegate. Equivilent to calling super
    // on an overrided method, this is not recursive, although it appears that way. neat huh?
    return [self swizzled_init];
}

// This code will be called immediately after application:didFinishLaunchingWithOptions:. We need
// to process notifications in cold-start situations
- (void)createNotificationChecker:(NSNotification *)notification
{
    if (notification){
        NSDictionary *launchOptions = [notification userInfo];
        NSString *apiKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"API_KEY"];
        [Bit6 startWithApiKey:apiKey pushNotificationMode:Bit6PushNotificationMode_DEVELOPMENT launchingWithOptions:launchOptions];
    }
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedIncomingCallNotification:) name:Bit6IncomingCallNotification object:nil];
}


- (id) getCommandInstance:(NSString*)className
{
    return [self.viewController getCommandInstance:className];
}


- (void)application:(UIApplication *)application
        didReceiveRemoteNotification:(NSDictionary *)userInfo
              fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    [[self getAppManager] didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}


- (void) application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken");
    [[NSNotificationCenter defaultCenter] postNotificationName:Bit6DidRegisterForRemoteNotifications object:nil userInfo:@{@"deviceToken":deviceToken}];
}

- (void) application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError");
    [[NSNotificationCenter defaultCenter] postNotificationName:Bit6DidFailToRegisterForRemoteNotifications object:nil userInfo:@{@"error":error}];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    NSLog(@"didRegisterUserNotificationSettings");
    if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
        [application registerForRemoteNotifications];
    }
}

//putting from appmanager

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler
{
    NSLog(@"handleActionWithIdentifier");

    if ([identifier isEqualToString:@"com.bit6.actionDecline"]) {
        NSNotification *notification = [[NSNotification alloc] initWithName:@"" object:@"" userInfo:userInfo];
        Bit6CallController *callController = [Bit6 callControllerFromIncomingCallNotification:notification];
        if (callController) {
            // [Bit6 sharedInstance].backgroundCallController = callController;
            // [Bit6 sharedInstance].actionNotificationHandler = completionHandler;
            // [callController declineCall];
        }
        else {
            completionHandler();
        }
    }
    else if ([identifier isEqualToString:@"com.bit6.actionAnswer"]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:userInfo];
        dict[@"answered"] = @YES;

        if (Bit6.session.authenticated) {
            [[NSNotificationCenter defaultCenter] postNotificationName:Bit6IncomingCallNotification object:self userInfo:dict];
        }
        completionHandler();
    }
}


- (void) didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    //[appManager didReceiveRemoteNotification: userInfo fetchCompletionHandler:completionHandler];
//    [[Bit6PushNotificationCenter sharedInstance] bit6RemoteNotificationReceived:userInfo fetchCompletionHandler:completionHandler];
}


- (void) receivedIncomingCallNotification:(NSNotification*)notification
{
    // NSLog(@"receivedIncomingCallNotification");
}

- (void) answerCall:(Bit6CallController*)callController
{
    if (!_handlingIncomingCall) {
        return;
    }

    //create the in-call UIViewController
    Bit6CallViewController *callVC = [self inCallViewController];

    //start the call
    [callController connectToViewController:callVC];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (!_handlingIncomingCall) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if ([object isKindOfClass:[Bit6CallController class]]) {
            if ([keyPath isEqualToString:@"callState"]) {
                [self callStateChangedNotification:object];
            }
        }
    });
}

- (void) callStateChangedNotification:(Bit6CallController*)callController
{
    if (!_handlingIncomingCall) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        //it's a missed call: remove the observer, dismiss the incoming-call prompt and the viewController
        if (callController.callState == Bit6CallState_MISSED) {
            [callController removeObserver:self forKeyPath:@"callState"];
            [Bit6.incomingCallNotificationBanner dismiss];
            self.callController = nil;
            [Bit6 dismissCallController:callController];
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Missed Call from %@",callController.otherDisplayName] message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
        //the call is starting: show the viewController
        else if (callController.callState == Bit6CallState_PROGRESS) {
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

#pragma mark -

- (Bit6CallViewController*) inCallViewController
{
    return [Bit6CallViewController createDefaultCallViewController];
}

- (UIView*) incomingCallNotificationBannerContentView
{
    NSLog(@"incomingCallNotificationBannerContentView");
    int numberOfLinesInMSG = 1;
    CGFloat padding = 10.0f;
    CGFloat separation = 3.0f;
    CGFloat titleHeight = 19.0f;
    CGFloat messageHeight = 17*numberOfLinesInMSG+5*(numberOfLinesInMSG-1);
    CGFloat buttonsAreaHeight = 60.0f;
    CGFloat height = padding*2+titleHeight+separation+messageHeight+buttonsAreaHeight;

    CGRect frame = [[UIScreen mainScreen] bounds];
    frame.size.height = height;

    NSString *deviceType = [UIDevice currentDevice].model;
    if([deviceType hasPrefix:@"iPad"]){
        CGFloat width = 450;
        frame.origin.x = (frame.size.width-width)/2.0;
        frame.size.width = width;
    }

    UIView *contentView = [[UIView alloc] initWithFrame:frame];
    contentView.backgroundColor = [UIColor colorWithRed:47/255.0f green:49/255.0f blue:50/255.0f alpha:1.0];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, padding, frame.size.width - padding*2, titleHeight)];
    titleLabel.font = [UIFont boldSystemFontOfSize:17];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.tag = 15;
    [contentView addSubview:titleLabel];

    UILabel *msgLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, CGRectGetMaxY(titleLabel.frame)+separation, frame.size.width - padding*2, messageHeight)];
    msgLabel.font = [UIFont systemFontOfSize:15];
    msgLabel.textColor = [UIColor whiteColor];
    msgLabel.tag = 16;
    msgLabel.numberOfLines = numberOfLinesInMSG;
    [contentView addSubview:msgLabel];

    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
    button1.tag = 17;
    button1.frame = CGRectMake(padding, CGRectGetMaxY(msgLabel.frame)+padding+6, (contentView.frame.size.width-padding*3)/2, buttonsAreaHeight-padding*2);
    [button1 setBackgroundImage:[Bit6Utils imageWithColor:[UIColor redColor]] forState:UIControlStateNormal];
    button1.layer.cornerRadius = 10.0f;
    button1.clipsToBounds = YES;
    [button1 setTitle:@"Decline" forState:UIControlStateNormal];
    [contentView addSubview:button1];

    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    button2.tag = 18;
    button2.frame = CGRectMake(CGRectGetMaxX(button1.frame)+padding, CGRectGetMaxY(msgLabel.frame)+padding+6, (contentView.frame.size.width-padding*3)/2, buttonsAreaHeight-padding*2);
    [button2 setBackgroundImage:[Bit6Utils imageWithColor:[UIColor blueColor]] forState:UIControlStateNormal];
    button2.layer.cornerRadius = 10.0f;
    button2.clipsToBounds = YES;
    [button2 setTitle:@"Answer" forState:UIControlStateNormal];
    [contentView addSubview:button2];

    return contentView;
}
@end
