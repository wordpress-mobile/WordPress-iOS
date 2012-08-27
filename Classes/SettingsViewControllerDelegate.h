//
//  SettingsViewControllerDelegate.h
//  WordPress
//
//  Created by Eric Johnson on 8/24/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SettingsViewControllerDelegate <NSObject>
- (void)controllerDidDismiss:(UIViewController *)controller cancelled:(BOOL)cancelled;
@end
