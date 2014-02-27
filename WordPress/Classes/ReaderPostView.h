//
//  ReaderPostView.h
//  WordPress
//
//  Created by Michael Johnston on 11/19/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPContentView.h"

@class ReaderPostView;

@protocol ReaderPostViewDelegate <WPContentViewDelegate>
- (void)postView:(ReaderPostView *)postView didReceiveLikeAction:(id)sender;
- (void)postView:(ReaderPostView *)postView didReceiveReblogAction:(id)sender;
- (void)postView:(ReaderPostView *)postView didReceiveCommentAction:(id)sender;
@end


@interface ReaderPostView : WPContentView {
    
}

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, weak) id <ReaderPostViewDelegate> delegate;
@property (nonatomic, assign) BOOL hidesAttribution;

+ (CGFloat)heightForPost:(ReaderPost *)post withWidth:(CGFloat)width showFullContent:(BOOL)showFullContent;
+ (CGFloat)heightWithoutAttributionForPost:(ReaderPost *)post withWidth:(CGFloat)width showFullContent:(BOOL)showFullContent;

- (id)initWithFrame:(CGRect)frame showFullContent:(BOOL)showFullContent;
- (void)configurePost:(ReaderPost *)post withWidth:(CGFloat)width;
- (void)setAvatar:(UIImage *)avatar;

@end
