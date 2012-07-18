//
//  CommentViewController.h
//  WordPress
//
//  Created by Janakiram on 05/09/08.
//

#import <UIKit/UIKit.h>
#import "ReplyToCommentViewController.h"
#import "EditCommentViewController.h"
#import "CommentsViewController.h"
#import "Comment.h"

@protocol CommentViewControllerDelegate;

@interface CommentViewController : UIViewController <ReplyToCommentViewControllerDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UIWebViewDelegate> {

	CommentsViewController *commentsViewController;
	EditCommentViewController *editCommentViewController;
    
    IBOutlet UIImageView *gravatarImageView;
    IBOutlet UILabel *commentAuthorLabel;
    IBOutlet UIButton *commentAuthorUrlButton;
	IBOutlet UIButton *commentAuthorEmailButton;
	IBOutlet UIButton *commentPostTitleButton;
	IBOutlet UILabel *commentPostTitleLabel;
    IBOutlet UILabel *commentDateLabel;
    IBOutlet UIWebView *commentBodyWebView;
	
	IBOutlet UIView *labelHolder;
	IBOutlet UILabel *pendingLabel;
	IBOutlet UIView *pendingLabelHolder;
    IBOutlet UIToolbar *toolbar;

    UIBarButtonItem *segmentBarItem;
    UISegmentedControl *segmentedControl;

    ReplyToCommentViewController *replyToCommentViewController;
    BOOL connectionStatus;
	//to control whether
	BOOL wasLastCommentPending;
	BOOL isVisible;
    BOOL isShowingActionSheet;
}


- (void)launchReplyToComments;
- (void)launchDeleteCommentActionSheet;
- (void)launchEditComment;
- (void)spamComment;
- (IBAction)viewURL;
- (IBAction)sendEmail;
- (IBAction)handlePostTitleButtonTapped:(id)sender;

- (void)segmentAction:(id)sender;
- (void)showComment:(Comment *)comment;
- (void)dismissEditViewController;
- (void)closeReplyViewAndSelectTheNewComment;
- (void)cancelView:(id)sender;

- (void)deleteComment;
- (void)approveComment;
- (void)unApproveComment;
- (void)addOrRemoveSegmentedControl;

@property (nonatomic, retain) ReplyToCommentViewController *replyToCommentViewController;
@property (nonatomic, retain) EditCommentViewController *editCommentViewController;
@property (nonatomic, retain) CommentsViewController *commentsViewController;
@property (nonatomic, retain) Comment *comment;
@property (nonatomic, retain) IBOutlet UIButton *commentAuthorUrlButton;
@property (nonatomic, retain) IBOutlet UIButton *commentAuthorEmailButton;
@property (nonatomic, retain) IBOutlet UIButton *commentPostTitleButton;
@property (nonatomic, retain) IBOutlet UILabel *commentPostTitleLabel;
@property (nonatomic, assign) id<CommentViewControllerDelegate> delegate;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;

@property BOOL wasLastCommentPending;
@property BOOL isVisible;

@end

@protocol CommentViewControllerDelegate <NSObject>

- (BOOL)hasPreviousComment;
- (BOOL)hasNextComment;
- (void)showPreviousComment;
- (void)showNextComment;

@end