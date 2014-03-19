//
//  AppDelegate.m
//
//  Copyright 2012 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "AppDelegate.h"

#import <GooglePlus/GooglePlus.h>
#import "MasterViewController.h"

@interface AppDelegate () <GPPDeepLinkDelegate>

@end

@implementation AppDelegate

// DO NOT USE THIS CLIENT ID. IT WILL NOT WORK FOR YOUR APP.
// Please use the client ID created for you by Google.
static NSString * const kClientID =
    @"452265719636-qbqmhro0t3j9jip1npl69a3er7biidd2.apps.googleusercontent.com";

#pragma mark Object life-cycle.


- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Set app's client ID for |GPPSignIn| and |GPPShare|.
  [GPPSignIn sharedInstance].clientID = kClientID;

  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  MasterViewController *masterViewController =
      [[MasterViewController alloc] initWithNibName:@"MasterViewController"
                                             bundle:nil];
  self.navigationController =
      [[UINavigationController alloc]
          initWithRootViewController:masterViewController];
  self.window.rootViewController = self.navigationController;
  [self.window makeKeyAndVisible];

  // Read Google+ deep-link data.
  [GPPDeepLink setDelegate:self];
  [GPPDeepLink readDeepLinkAfterInstall];
  return YES;
}

- (BOOL)application:(UIApplication *)application
              openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation {
  return [GPPURLHandler handleURL:url
                sourceApplication:sourceApplication
                       annotation:annotation];
}

#pragma mark - GPPDeepLinkDelegate

- (void)didReceiveDeepLink:(GPPDeepLink *)deepLink {
  // An example to handle the deep link data.
  UIAlertView *alert = [[UIAlertView alloc]
          initWithTitle:@"Deep-link Data"
                message:[deepLink deepLinkID]
               delegate:nil
      cancelButtonTitle:@"OK"
      otherButtonTitles:nil];
  [alert show];
}

@end
