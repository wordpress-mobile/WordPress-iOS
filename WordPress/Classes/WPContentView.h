//
//  WPContentView.h
//  WordPress
//
//  Created by Michael Johnston on 11/19/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderPost.h"
#import "DTAttributedTextContentView.h"
#import "ReaderMediaQueue.h"

@class WPContentView;

@protocol WPContentViewDelegate <NSObject>
@optional
- (void)contentView:(WPContentView *)contentView didReceiveFollowAction:(id)sender;
- (void)contentView:(WPContentView *)contentView didReceiveTagAction:(id)sender;
- (void)contentView:(WPContentView *)contentView didReceiveLikeAction:(id)sender;
- (void)contentView:(WPContentView *)contentView didReceiveReblogAction:(id)sender;
- (void)contentView:(WPContentView *)contentView didReceiveCommentAction:(id)sender;
- (void)contentView:(WPContentView *)contentView didReceiveLinkAction:(id)sender;
- (void)contentView:(WPContentView *)contentView didReceiveImageLinkAction:(id)sender;
- (void)contentView:(WPContentView *)contentView didReceiveVideoLinkAction:(id)sender;
- (void)contentView:(WPContentView *)contentView didReceiveFeaturedImageAction:(id)sender;
- (void)postViewDidLoadAllMedia:(WPContentView *)postView;
@end

@interface WPContentView : UIView<DTAttributedTextContentViewDelegate, ReaderMediaQueueDelegate> {
    
}

@property (nonatomic, weak) id<WPContentViewDelegate> delegate;
@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) UIImageView *cellImageView;
@property (nonatomic, strong) UIImageView *avatarImageView;

+ (CGFloat)heightForPost:(ReaderPost *)post withWidth:(CGFloat)width;
- (id)initWithFrame:(CGRect)frame showFullContent:(BOOL)showFullContent;
- (void)setFeaturedImage:(UIImage *)image;
- (void)setAvatar:(UIImage *)avatar;
- (void)updateActionButtons;
- (void)reset;
- (void)configurePost:(ReaderPost *)post;

@end
