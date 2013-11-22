//
//  ReaderPostView.h
//  WordPress
//
//  Created by Michael Johnston on 11/19/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderPost.h"
#import "DTAttributedTextContentView.h"
#import "ReaderMediaQueue.h"

@interface ReaderPostView : UIView<DTAttributedTextContentViewDelegate, ReaderMediaQueueDelegate>

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) UIImageView *cellImageView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UIButton *tagButton;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *reblogButton;
@property (nonatomic, strong) UIButton *commentButton;
@property (nonatomic, strong) UIButton *timeButton;

+ (CGFloat)heightForPost:(ReaderPost *)post withWidth:(CGFloat)width;
- (id)initWithFrame:(CGRect)frame showFullContent:(BOOL)showFullContent;
- (void)setFeaturedImage:(UIImage *)image;
- (void)setAvatar:(UIImage *)avatar;
- (void)updateControlBar;
- (void)reset;
- (void)configurePost:(ReaderPost *)post;
- (void)updateLayout;

@end
