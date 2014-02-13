/*
 * ReaderPostDetailViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>
#import "ReaderPost.h"
#import "ReaderPostView.h"

@interface ReaderPostDetailViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, ReaderPostViewDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, assign) BOOL showInlineActionBar;

- (id)initWithPost:(ReaderPost *)post featuredImage:(UIImage *)image avatarImage:(UIImage *)avatarImage;
- (void)updateFeaturedImage:(UIImage *)image;

@end
