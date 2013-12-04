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

extern CGFloat const WPTableViewTopMargin;

@interface WPTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UIAlertViewDelegate, SettingsViewControllerDelegate, UIViewControllerRestoration>

@property (nonatomic, strong) Blog *blog;
@property (nonatomic, readonly) BOOL isScrolling;
@property (nonatomic) BOOL incrementalLoadingSupported;

- (void)promptForPassword;
- (NSString *)noResultsTitleText;
- (NSString *)noResultsMessageText;
- (UIView *)noResultsAccessoryView;
- (void)configureNoResultsView;

@end
