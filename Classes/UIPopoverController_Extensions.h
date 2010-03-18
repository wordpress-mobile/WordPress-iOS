//
//  UIPopoverController_Extensions.h
//  WordPress
//
//  Created by Jonathan Wight on 03/18/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIPopoverController (UIPopoverController_Extensions)

+ (UIPopoverController *)currentPopoverController;
+ (void)setCurrentPopoverController:(UIPopoverController *)inCurrentPopoverController;

@end
