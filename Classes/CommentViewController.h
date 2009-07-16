//
//  CommentViewController.h
//  WordPress
//
//  Created by Janakiram on 05/09/08.
//

#import <UIKit/UIKit.h>
#import "GravatarImageView.h"

#define kCustomButtonHeight     30.0


@interface CommentViewController : UIViewController <UIScrollViewDelegate> {
    IBOutlet UIScrollView *scrollView;
    
    IBOutlet GravatarImageView *gravatarImageView;
    IBOutlet UILabel *commentAuthorLabel;
    IBOutlet UILabel *commentAuthorUrlLabel;
    IBOutlet UILabel *commentPostTitleLabel;
    IBOutlet UILabel *commentDateLabel;
    IBOutlet UILabel *commentBodyLabel;

    IBOutlet UIToolbar *approveAndUnapproveButtonBar;
    IBOutlet UIToolbar *deleteButtonBar;

    IBOutlet UIBarButtonItem *approveButton;
    IBOutlet UIBarButtonItem *unapproveButton;
    IBOutlet UIBarButtonItem *spamButton1;
    IBOutlet UIBarButtonItem *spamButton2;

    UIBarButtonItem *segmentBarItem;
    UISegmentedControl *segmentedControl;

    UIAlertView *progressAlert;
    
    NSMutableArray *commentDetails;
    int currentIndex;
    BOOL connectionStatus;
}

- (void)segmentAction:(id)sender;
- (void)showComment:(NSArray *)comments atIndex:(int)row;

- (void)deleteComment:(id)sender;
- (void)approveComment:(id)sender;
- (void)unApproveComment:(id)sender;
- (void)spamComment:(id)sender;

@end
