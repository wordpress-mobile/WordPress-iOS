//
//  MFMailComposeViewController+StatusBarStyle.m
//  WordPress
//
//  Created by Cyril Chandelier on 26/04/15.
//  Copyright (c) 2015 WordPress. All rights reserved.
//

#import "MFMailComposeViewController+StatusBarStyle.h"

@implementation MFMailComposeViewController (StatusBarStyle)

#pragma mark - Status bar management

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return nil;
}

@end
