//
//  CommentsViewControllers.h
//  WordPress
//
//  Created by Janakiram on 02/09/08.
//

#import <Foundation/Foundation.h>

#import "CommentsTableViewDelegate.h"
#import "RefreshButtonView.h"

@class CommentViewController;

@interface CommentsViewController : UIViewController <UITableViewDataSource, CommentsTableViewDelegate, UIAccelerometerDelegate> {
@private
    IBOutlet UITableView *commentsTableView;

    IBOutlet UIToolbar *editToolbar;
    UIBarButtonItem *editButtonItem;
    RefreshButtonView *refreshButton;
	
	CommentViewController *commentViewController;

    IBOutlet UIBarButtonItem *approveButton;
    IBOutlet UIBarButtonItem *unapproveButton;
    IBOutlet UIBarButtonItem *spamButton;
    IBOutlet UIBarButtonItem *deleteButton;
    BOOL editing;

    NSMutableArray *commentsArray;
    NSMutableDictionary *commentsDict;
    NSMutableArray *selectedComments;
    UIAlertView *progressAlert;
    int indexForCurrentPost;
	UISegmentedControl *segmentedControl;
	NSIndexPath *selectedIndexPath;
	
	// added to distinguish a single posts's comments VC
	// from the master VC's comments list.
	// consider rethinking how this is done.
	BOOL isSecondaryViewController;
}

@property (readonly) UIBarButtonItem *editButtonItem;
@property (nonatomic, retain) NSMutableArray *selectedComments;
@property (nonatomic, retain) NSMutableArray *commentsArray;
@property int indexForCurrentPost;
@property (nonatomic, retain) CommentViewController *commentViewController;
@property (nonatomic, retain) UISegmentedControl *segmentedControl;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@property (nonatomic, assign) BOOL isSecondaryViewController;

- (IBAction)deleteSelectedComments:(id)sender;
- (IBAction)approveSelectedComments:(id)sender;
- (IBAction)unapproveSelectedComments:(id)sender;
- (IBAction)spamSelectedComments:(id)sender;
- (void)refreshCommentsList;
- (void)setIndexForCurrentPost:(int)index;
- (void)showCommentAtIndex:(int)index;

@end
