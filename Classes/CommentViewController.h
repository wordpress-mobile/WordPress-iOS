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

@interface CommentViewController : UIViewController <UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UIWebViewDelegate> {

	CommentsViewController *commentsViewController;
	EditCommentViewController *editCommentViewController;
    
    IBOutlet UIImageView *gravatarImageView;
    IBOutlet UILabel *commentAuthorLabel;
    IBOutlet UIButton *commentAuthorUrlButton;
	IBOutlet UIButton *commentAuthorEmailButton;
    IBOutlet UILabel *commentPostTitleLabel;
    IBOutlet UILabel *commentDateLabel;
    IBOutlet UIWebView *commentBodyWebView;
	
	IBOutlet UIView *labelHolder;
	IBOutlet UILabel *pendingLabel;
	IBOutlet UIView *pendingLabelHolder;

    IBOutlet UIToolbar *approveAndUnapproveButtonBar;
    IBOutlet UIToolbar *deleteButtonBar;

    IBOutlet UIBarButtonItem *approveButton;
    IBOutlet UIBarButtonItem *unapproveButton;
    IBOutlet UIBarButtonItem *spamButton1;
    IBOutlet UIBarButtonItem *spamButton2;
    IBOutlet UIBarButtonItem *pendingApproveButton;
	
	IBOutlet UIBarButtonItem *deleteButton;

    UIBarButtonItem *segmentBarItem;
    UISegmentedControl *segmentedControl;

    UIAlertView *progressAlert;
    
    ReplyToCommentViewController *replyToCommentViewController;
    BOOL connectionStatus;
	//to control whether
	BOOL wasLastCommentPending;
	BOOL isVisible;
}


- (IBAction)launchModerateMenu;
- (IBAction)launchReplyToComments;
- (IBAction)launchDeleteCommentActionSheet;
- (IBAction)viewURL;
- (IBAction)sendEmail;

- (void)segmentAction:(id)sender;
- (void)showComment:(Comment *)comment;
- (void)dismissEditViewController;
- (void) closeReplyViewAndSelectTheNewComment;
- (void)cancelView:(id)sender;

- (void)deleteComment:(id)sender;
- (void)approveComment:(id)sender;
- (void)unApproveComment:(id)sender;
- (void)spamComment:(id)sender;
- (void)addOrRemoveSegmentedControl;

@property (nonatomic, retain) ReplyToCommentViewController *replyToCommentViewController;
@property (nonatomic, retain) EditCommentViewController *editCommentViewController;
@property (nonatomic, retain) CommentsViewController *commentsViewController;
@property (nonatomic, retain) Comment *comment;
@property (nonatomic, retain) IBOutlet UIButton *commentAuthorUrlButton;
@property (nonatomic, retain) IBOutlet UIButton *commentAuthorEmailButton;
@property BOOL wasLastCommentPending;
@property BOOL isVisible;

@end
