//
//  MFMessageComposeViewController+StatusBarStyle.m
//  WordPress
//
//  Created by Cyril Chandelier on 03/05/15.
//  Copyright (c) 2015 WordPress. All rights reserved.
//

#import "MFMessageComposeViewController+StatusBarStyle.h"

@implementation MFMessageComposeViewController (StatusBarStyle)

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
