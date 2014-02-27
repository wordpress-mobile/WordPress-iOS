//
//  ReaderPostTableViewCell.h
//  WordPress
//
//  Created by Eric J on 4/4/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderPost.h"
#import "WPTableViewCell.h"

@class ReaderPostView;

@interface ReaderPostTableViewCell : WPTableViewCell
@property (nonatomic, strong) UIImageView *avatarImageView;

+ (CGFloat)cellHeightForPost:(ReaderPost *)post withWidth:(CGFloat)width;
+ (ReaderPostTableViewCell *)cellForSubview:(UIView *)subview;

- (void)configureCell:(ReaderPost *)post withWidth:(CGFloat)width;

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) ReaderPostView *postView;

@end
