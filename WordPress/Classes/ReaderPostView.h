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

@class ReaderPostView;

@protocol ReaderPostViewDelegate <NSObject>
@optional
- (void)postView:(ReaderPostView *)postView didReceiveFollowAction:(id)sender;
- (void)postView:(ReaderPostView *)postView didReceiveTagAction:(id)sender;
- (void)postView:(ReaderPostView *)postView didReceiveLikeAction:(id)sender;
- (void)postView:(ReaderPostView *)postView didReceiveReblogAction:(id)sender;
- (void)postView:(ReaderPostView *)postView didReceiveCommentAction:(id)sender;
- (void)postView:(ReaderPostView *)postView didReceiveLinkAction:(id)sender;
- (void)postView:(ReaderPostView *)postView didReceiveImageLinkAction:(id)sender;
- (void)postView:(ReaderPostView *)postView didReceiveVideoLinkAction:(id)sender;
- (void)postView:(ReaderPostView *)postView didReceiveFeaturedImageAction:(id)sender;
- (void)postViewDidLoadAllMedia:(ReaderPostView *)postView;
@end

@interface ReaderPostView : UIView<DTAttributedTextContentViewDelegate, ReaderMediaQueueDelegate> {
    
}

@property (nonatomic, weak) id<ReaderPostViewDelegate> delegate;
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
- (void)refreshMediaLayout;

@end
