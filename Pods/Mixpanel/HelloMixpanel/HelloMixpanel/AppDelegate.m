//
// AppDelegate.m
// HelloMixpanel
//
// Copyright 2012 Mixpanel
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "Mixpanel.h"

#import "AppDelegate.h"

#import "ViewController.h"

// IMPORTANT!!! replace with you api token from https://mixpanel.com/account/
#define MIXPANEL_TOKEN @"YOUR_MIXPANEL_PROJECT_TOKEN"

@implementation AppDelegate

- (void)dealloc
{
    [_startTime release];
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];

    // Override point for customization after application launch.

    // Initialize the MixpanelAPI object
    self.mixpanel = [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];

    self.mixpanel.checkForSurveysOnActive = YES;
    self.mixpanel.showSurveyOnActive = YES; //Change this to NO to show your surveys manually.

    // Set the upload interval to 20 seconds for demonstration purposes. This would be overkill for most applications.
    self.mixpanel.flushInterval = 20; // defaults to 60 seconds

    // Set some super properties, which will be added to every tracked event
    [self.mixpanel registerSuperProperties:@{@"Plan": @"Premium"}];

    // Name a user in Mixpanel Streams
    self.mixpanel.nameTag = @"Walter Sobchak";

    self.viewController = [[[ViewController alloc] initWithNibName:@"ViewController" bundle:nil] autorelease];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];

    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];

    return YES;
}

#pragma mark - Push notifications

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    [self.mixpanel.people addPushDeviceToken:devToken];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"%@ push registration error is expected on simulator", self);
#else
    NSLog(@"%@ push registration error: %@", self, err);
#endif
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    // Show alert for push notifications recevied while the app is running
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                    message:userInfo[@"aps"][@"alert"]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

#pragma mark - Session timing example

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    self.startTime = [NSDate date];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"%@ will resign active", self);
    NSNumber *seconds = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceDate:self.startTime]];
    [[Mixpanel sharedInstance] track:@"Session" properties:[NSDictionary dictionaryWithObject:seconds forKey:@"Length"]];
}

#pragma mark - Background task tracking test

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    self.bgTask = [application beginBackgroundTaskWithExpirationHandler:^{

        NSLog(@"%@ background task %lu cut short", self, (unsigned long)self.bgTask);

        [application endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSLog(@"%@ starting background task %lu", self, (unsigned long)self.bgTask);

        // track some events and set some people properties
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel registerSuperProperties:@{@"Background Super Property": @"Hi!"}];
        [mixpanel track:@"Background Event"];
        [mixpanel.people set:@"Background Property" to:[NSDate date]];

        NSLog(@"%@ ending background task %lu", self, (unsigned long)self.bgTask);
        [application endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    });

    NSLog(@"%@ dispatched background task %lu", self, (unsigned long)self.bgTask);
}

@end
