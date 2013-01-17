//
//  NoteCommentCell.h
//  WordPress
//
//  Created by Beau Collins on 12/6/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FollowButton.h>

@interface NoteCommentCell : UITableViewCell
@property BOOL parentComment;
@property (nonatomic, strong) FollowButton *followButton;

- (void)setAvatarURL:(NSURL *)avatarURL;
- (void)showLoadingIndicator;
- (void)displayAsParentComment;

@end
