//
//  ReaderPostDetailViewController.h
//  WordPress
//
//  Created by Eric J on 3/21/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderPost.h"
#import "ReaderPostView.h"

@interface ReaderPostDetailViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, ReaderPostViewDelegate>
@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, assign) BOOL showInlineActionBar;

- (id)initWithPost:(ReaderPost *)post featuredImage:(UIImage *)image;
- (void)updateFeaturedImage:(UIImage *)image;

@end
