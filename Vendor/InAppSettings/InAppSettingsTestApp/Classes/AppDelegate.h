//
//  InAppSettingsTestAppAppDelegate.h
//  InAppSettingsTestApp
//
//  Created by David Keegan on 11/24/09.
//  Copyright InScopeApps{+} 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
    UIWindow *window;
    UITabBarController *tabBarController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;

@end
