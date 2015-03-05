//
//  AppDelegate+notification.h
//  LeanPlum
//
//  Created by Telerik Inc.
//
//

#import "AppDelegate.h"
#import "Bit6SDK/Bit6CallController.h"


@interface AppDelegate (bit6)

- (id) getCommandInstance:(NSString*)className;

@property (strong, nonatomic) Bit6CallController *callController;

@end
