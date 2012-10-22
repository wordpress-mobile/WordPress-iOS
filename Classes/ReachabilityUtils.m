//
//  ReachabilityUtils.m
//  WordPress
//
//  Created by Eric on 8/29/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "ReachabilityUtils.h"
#import "WordPressAppDelegate.h"

@implementation ReachabilityUtils

+ (BOOL)isInternetReachable {
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    return appDelegate.connectionAvailable;
}


+ (void)showAlertNoInternetConnection {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Connection", @"")
                                                        message:NSLocalizedString(@"The Internet connection appears to be offline.", @"")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                              otherButtonTitles:nil];
    [alertView show];
}


+ (void)showAlertNoInternetConnectionWithDelegate:(id)delegate {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Connection", @"")
                                                        message:NSLocalizedString(@"The Internet connection appears to be offline.", @"")
                                                       delegate:delegate
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                              otherButtonTitles:NSLocalizedString(@"Retry?", @""), nil];
    [alertView show];
}


@end
