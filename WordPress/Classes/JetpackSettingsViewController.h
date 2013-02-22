//
//  JetpackSettingsViewController.h
//  WordPress
//
//  Created by Eric Johnson on 8/24/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Blog;

typedef void(^JetpackSettingsCompletionBlock)(BOOL didAuthenticate);

@interface JetpackSettingsViewController : UITableViewController
@property (nonatomic, assign) BOOL canBeSkipped;
// Always add the buttons to the view. Don't touch the navigation bar
@property (nonatomic, assign) BOOL ignoreNavigationController;
@property (nonatomic, copy) JetpackSettingsCompletionBlock completionBlock;
- (void)setCompletionBlock:(JetpackSettingsCompletionBlock)completionBlock; // Just so Xcode autocompletes the block
- (id)initWithBlog:(Blog *)blog;
@end