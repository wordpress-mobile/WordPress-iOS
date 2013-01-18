//
//  ReplyToCommentViewController.h
//  WordPress
//
//  Created by John Bickerstaff on 12/20/09.
//  
//

#import <UIKit/UIKit.h>
#import "Comment.h"
#import "EditCommentViewController.h"

@class CommentViewController;

@protocol ReplyToCommentViewControllerDelegate <NSObject>

- (void)cancelReplyToCommentViewController:(id)sender;

@optional

- (void)closeReplyViewAndSelectTheNewComment;

@end

@interface ReplyToCommentViewController : EditCommentViewController

@property (nonatomic, strong) id<ReplyToCommentViewControllerDelegate> delegate;

- (void)cancelView:(id)sender;

@end
