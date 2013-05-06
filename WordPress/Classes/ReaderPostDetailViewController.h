//
//  ReaderPostDetailViewController.h
//  WordPress
//
//  Created by Eric J on 3/21/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderPost.h"
#import "WPRefreshViewController.h"

@interface ReaderPostDetailViewController : WPRefreshViewController

@property (nonatomic, strong) ReaderPost *post;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIBarButtonItem *likeButton;
@property (nonatomic, strong) UIBarButtonItem *followButton;
@property (nonatomic, strong) UIBarButtonItem *reblogButton;
@property (nonatomic, strong) UIBarButtonItem *actionButton;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIImageView *blavatarImageView;
@property (nonatomic, strong) UILabel *titleLabel;

- (id)initWithPost:(ReaderPost *)apost;
- (void)handleLikeButtonTapped:(id)sender;
- (void)handleFollowButtonTapped:(id)sender;
- (void)handleReblogButtonTapped:(id)sender;
- (void)handleActionButtonTapped:(id)sender;
- (void)handleTitleButtonTapped:(id)sender;

@end
