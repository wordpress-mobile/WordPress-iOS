//
//  ReaderPostDetailViewController.h
//  WordPress
//
//  Created by Eric J on 3/21/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderPost.h"

@interface ReaderPostDetailViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) ReaderPost *post;

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UIView *contentView;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *likeButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *followButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *reblogButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *actionButton;
@property (nonatomic, strong) IBOutlet UIView *headerView;
@property (nonatomic, strong) IBOutlet UIImageView *blavatarImageView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;

- (id)initWithPost:(ReaderPost *)apost;
- (IBAction)handleLikeButtonTapped:(id)sender;
- (IBAction)handleFollowButtonTapped:(id)sender;
- (IBAction)handleReblogButtonTapped:(id)sender;
- (IBAction)handleActionButtonTapped:(id)sender;
- (IBAction)handleTitleButtonTapped:(id)sender;

@end
