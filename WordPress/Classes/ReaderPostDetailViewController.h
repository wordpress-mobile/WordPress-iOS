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
#import "ReaderCommentTableViewCell.h"

@interface ReaderPostDetailViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, ReaderPostViewDelegate, ReaderCommentTableViewCellDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, assign) BOOL showInlineActionBar;

- (id)initWithPost:(ReaderPost *)post featuredImage:(UIImage *)image avatarImage:(UIImage *)avatarImage;
- (id)initWithPost:(ReaderPost *)post avatarImageURL:(NSURL *)avatarImageURL;

- (void)updateFeaturedImage:(UIImage *)image;

@end
