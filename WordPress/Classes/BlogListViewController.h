//
//  BlogListViewController.h
//  WordPress
//
//  Created by Michael Johnston on 11/8/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BlogListViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIDataSourceModelAssociation>

- (void)bypassBlogListViewController;
- (BOOL)shouldBypassBlogListViewControllerWhenSelectedFromTabBar;

@end
