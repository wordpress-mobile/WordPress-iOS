//
//  NoteCommentView.h
//  WordPress
//
//  Created by Beau Collins on 12/6/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DTCoreText.h"
#import "FollowButton.h"

@class NoteCommentView;

@protocol NoteCommentViewDelegate <NSObject>

@optional

- (void)commentView:(NoteCommentView *)commentView didRequestURL:(NSURL *)url;


@end

@interface NoteCommentView : UIView
@property (nonatomic, assign) id <NoteCommentViewDelegate> delegate;
@property (nonatomic, strong) NSDictionary *comment;
@property (nonatomic, strong) DTAttributedTextContentView *contentView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) UIButton *profileButton;
@property (nonatomic, strong) UIButton *emailButton;
@property (nonatomic, strong) FollowButton *followButton;
@end
