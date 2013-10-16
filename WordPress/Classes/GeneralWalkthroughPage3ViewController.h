//
//  GeneralWalkthroughPage3ViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/23/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseNUXViewController.h"

@class WPWalkthroughOverlayView;
@interface GeneralWalkthroughPage3ViewController : BaseNUXViewController

@property (nonatomic, assign) CGFloat heightToUseForCentering;
@property (nonatomic, weak) UIView *containingView;

- (void)showCreateAccountView;
- (void)setUsername:(NSString *)username;
- (void)setPassword:(NSString *)password;
- (void)showAddUsersBlogsForWPCom;

@end
