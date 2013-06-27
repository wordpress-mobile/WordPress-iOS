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

- (void)configureCell:(ReaderPost *)post;
- (void)setReblogTarget:(id)target action:(SEL)selector;
- (void)setFeaturedImage:(UIImage *)image;
- (void)setAvatar:(UIImage *)avatar;

@end
