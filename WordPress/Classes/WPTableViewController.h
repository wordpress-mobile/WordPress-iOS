/*
 * WPTableViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "Blog.h"
#import "SettingsViewControllerDelegate.h"

@interface WPTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, SettingsViewControllerDelegate, UIViewControllerRestoration>

@property (nonatomic, strong) Blog *blog;
@property (nonatomic, readonly) BOOL isScrolling;
@property (nonatomic) BOOL incrementalLoadingSupported;

- (void)promptForPassword;
- (NSString *)noResultsText;

@end
