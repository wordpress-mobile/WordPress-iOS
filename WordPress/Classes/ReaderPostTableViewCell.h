//
//  ReaderPostTableViewCell.h
//  WordPress
//
//  Created by Eric J on 4/4/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderPost.h"
#import "ReaderTableViewCell.h"

@interface ReaderPostTableViewCell : ReaderTableViewCell
@property (nonatomic, strong) UIImageView *avatarImageView;

+ (CGFloat)cellHeightForPost:(ReaderPost *)post withWidth:(CGFloat)width;
+ (ReaderPostTableViewCell *)cellForSubview:(UIView *)subview;

- (void)configureCell:(ReaderPost *)post;
- (void)setFeaturedImage:(UIImage *)image;
- (void)setAvatar:(UIImage *)avatar;

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UIButton *tagButton;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *reblogButton;
@property (nonatomic, strong) UIButton *commentButton;

extern CGFloat const RPTVCMaxImageHeightPercentage;

- (void)updateControlBar;

@end
