/*
 * PostSettingsViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>
#import "AbstractPost.h"

@interface PostSettingsViewController : UITableViewController

@property (nonatomic, strong) NSString *statsPrefix;

- (id)initWithPost:(AbstractPost *)aPost;
- (void)endEditingAction:(id)sender;

@end
