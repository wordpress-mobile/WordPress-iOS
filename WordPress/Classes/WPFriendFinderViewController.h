//
//  WPFriendFinderViewController.h
//  WordPress
//
//  Created by Beau Collins on 5/31/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPWebAppViewController.h"
#import "FBRequest.h"

@interface WPFriendFinderViewController : WPWebAppViewController <FBRequestDelegate>

- (void)authorizeSource:(NSString *)source;
- (void)configureFriendFinder:(id)config;

@end

