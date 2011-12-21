//
//  InAppSettingsTestAppAppDelegate.m
//  InAppSettingsTestApp
//
//  Created by David Keegan on 11/24/09.
//  Copyright InScopeApps{+} 2009. All rights reserved.
//

#import "AppDelegate.h"
#import "InAppSettings.h"

@implementation AppDelegate

@synthesize window;
@synthesize tabBarController;

+ (void)initialize{
    if([self class] == [AppDelegate class]){
		[InAppSettings registerDefaults];
    }
}

- (void)applicationDidFinishLaunching:(UIApplication *)application{
    [window addSubview:tabBarController.view];
}

- (void)dealloc{
    [tabBarController release];
    [window release];
    [super dealloc];
}

@end

