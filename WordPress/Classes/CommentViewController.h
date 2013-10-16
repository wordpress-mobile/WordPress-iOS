//
//  CommentViewControllerTestViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/22/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Comment;
@class CommentsViewController;
@interface CommentViewController : UIViewController

@property (nonatomic, strong) Comment *comment;
@property (nonatomic, weak) CommentsViewController *commentsViewController;
@property BOOL wasLastCommentPending;

- (void)cancelView:(id)sender;
- (void)showComment:(Comment *)comment;

@end
