//
//  WPContentView.h
//  WordPress
//
//  Created by Michael Johnston on 11/19/13.
//  Moved from ReaderPostView by Eric J.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderPost.h"
#import "DTAttributedTextContentView.h"
#import "ReaderMediaQueue.h"
#import "WPContentViewProvider.h"
#import "ContentActionButton.h"

@class WPContentView;

@protocol WPContentViewDelegate <NSObject>
@optional
- (void)contentView:(WPContentView *)contentView didReceiveFollowAction:(id)sender;
- (void)contentView:(WPContentView *)contentView didReceiveTagAction:(id)sender;
- (void)contentView:(WPContentView *)contentView didReceiveLinkAction:(id)sender;
- (void)contentView:(WPContentView *)contentView didReceiveImageLinkAction:(id)sender;
- (void)contentView:(WPContentView *)contentView didReceiveVideoLinkAction:(id)sender;
- (void)contentView:(WPContentView *)contentView didReceiveFeaturedImageAction:(id)sender;
- (void)contentView:(WPContentView *)contentView didReceiveAuthorLinkAction:(id)sender;
- (void)contentViewDidLoadAllMedia:(WPContentView *)contentView;
@end

@interface WPContentView : UIView <DTAttributedTextContentViewDelegate, ReaderMediaQueueDelegate>

@property (nonatomic, weak) id<WPContentViewDelegate> delegate;
@property (nonatomic, weak) id<WPContentViewProvider> contentProvider;
@property (nonatomic, strong) UIImageView *cellImageView;
@property (nonatomic, weak, readonly) UIImageView *avatarImageView;
@property (nonatomic, weak, readonly) ContentActionButton *followButton;
@property (nonatomic, weak, readonly) UIButton *linkButton;

- (id)initWithFrame:(CGRect)frame;
- (void)setFeaturedImage:(UIImage *)image;
- (void)setAuthorDisplayName:(NSString *)authorName authorLink:(NSString *)authorLink;
- (UIButton *)addActionButtonWithImage:(UIImage *)buttonImage selectedImage:(UIImage *)selectedButtonImage;
- (void)removeActionButton:(UIButton *)button;
- (void)updateActionButtons;
- (void)refreshMediaLayout;
- (void)reset;

@end
