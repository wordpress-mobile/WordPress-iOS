//
//  CommentModerationUtils.h
//  WordPress
//
//  Created by Peter Boctor on 3/29/11.
//  Copyright 2011 WordPress. All rights reserved.
//
#import "Comment.h"
#import "ReplyToCommentViewController.h"

@interface CommentModerationUtils : NSObject
{
  Comment* comment;
  CommentsViewController *commentsViewController;
  ReplyToCommentViewController *replyToCommentViewController;
}

@property (nonatomic, retain) Comment* comment;
@property (nonatomic, retain) CommentsViewController *commentsViewController;
@property (nonatomic, retain) ReplyToCommentViewController *replyToCommentViewController;

+ (CommentModerationUtils *) instance;

- (void) deleteComment;
- (void) launchModerateMenuInView:(UIView*)view;
- (void) showReplyToCommentViewWithAnimation:(BOOL)animate;

// ReplyToCommentViewController methods
- (void) closeReplyViewAndSelectTheNewComment;
- (void)cancelView:(id)sender;

@end
