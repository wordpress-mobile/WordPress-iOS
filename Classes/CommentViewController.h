//
//  CommentViewController.h
//  WordPress
//
//  Created by Janakiram on 05/09/08.
//

#import <UIKit/UIKit.h>
#import "GravatarImageView.h"
#import "ReplyToCommentViewController.h"
#import "EditCommentViewController.h"
#import "CommentsViewController.h"

@interface CommentViewController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate> {

	CommentsViewController *commentsViewController;
	EditCommentViewController *editCommentViewController;
	
	IBOutlet UIScrollView *scrollView;
    
    IBOutlet GravatarImageView *gravatarImageView;
    IBOutlet UILabel *commentAuthorLabel;
    IBOutlet UILabel *commentAuthorUrlLabel;
	IBOutlet UILabel *commentAuthorEmailLabel;
    IBOutlet UILabel *commentPostTitleLabel;
    IBOutlet UILabel *commentDateLabel;
    IBOutlet UILabel *commentBodyLabel;
	
	IBOutlet UIView *labelHolder;
	IBOutlet UILabel *pendingLabel;
	IBOutlet UIView *pendingLabelHolder;

    IBOutlet UIToolbar *approveAndUnapproveButtonBar;
    IBOutlet UIToolbar *deleteButtonBar;

    IBOutlet UIBarButtonItem *approveButton;
    IBOutlet UIBarButtonItem *unapproveButton;
    IBOutlet UIBarButtonItem *spamButton1;
    IBOutlet UIBarButtonItem *spamButton2;
	
	IBOutlet UIBarButtonItem *deleteButton;

    UIBarButtonItem *segmentBarItem;
    UISegmentedControl *segmentedControl;

    UIAlertView *progressAlert;
    
    ReplyToCommentViewController *replyToCommentViewController;
	NSMutableArray *commentDetails;
	NSString *commentStatus;
    int currentIndex;
    BOOL connectionStatus;
	//to control whether
	BOOL wasLastCommentPending;
}


- (IBAction)launchModerateMenu;
- (IBAction)launchReplyToComments;
- (IBAction)launchDeleteCommentActionSheet;

- (void)segmentAction:(id)sender;
- (void)showComment:(NSArray *)comments atIndex:(int)row;

- (void)deleteComment:(id)sender;
- (void)approveComment:(id)sender;
- (void)unApproveComment:(id)sender;
- (void)spamComment:(id)sender;
- (void)cancelView:(id)sender;

@property (nonatomic, retain) ReplyToCommentViewController *replyToCommentViewController;
@property (nonatomic, retain) EditCommentViewController *editCommentViewController;
@property (nonatomic, retain) CommentsViewController *commentsViewController;
@property BOOL wasLastCommentPending;


@end
