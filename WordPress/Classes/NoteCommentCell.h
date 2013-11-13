//
//  NoteCommentCell.h
//  WordPress
//
//  Created by Beau Collins on 12/6/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DTCoreText/DTCoreText.h>
#import "FollowButton.h"

extern const CGFloat NoteCommentCellHeight;

@protocol NoteCommentCellDelegate <NSObject>

@optional

- (void)commentCell:(UITableViewCell *)cell didTapURL:(NSURL *)url;

@end

@interface NoteCommentCell : UITableViewCell
@property BOOL parentComment;
@property (nonatomic, strong) FollowButton *followButton;
@property (nonatomic, strong) NSURL *profileURL;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, assign) id <NoteCommentCellDelegate> delegate;
- (void)setAvatarURL:(NSURL *)avatarURL;
- (void)displayAsParentComment;
- (void)showLoadingIndicator;

@end
