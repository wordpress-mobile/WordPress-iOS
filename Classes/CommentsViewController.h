//
//  CommentsViewControllers.h
//  WordPress
//
//  Created by Janakiram on 02/09/08.
//

#import <Foundation/Foundation.h>

#import "CommentsTableViewDelegate.h"
#import "Blog.h"
#import "EGORefreshTableHeaderView.h"

@class CommentViewController;

@interface CommentsViewController : UIViewController <UITableViewDataSource, CommentsTableViewDelegate, UIAccelerometerDelegate, NSFetchedResultsControllerDelegate, EGORefreshTableHeaderDelegate> {
@private
    IBOutlet UITableView *commentsTableView;

    IBOutlet UIToolbar *editToolbar;
    UIBarButtonItem *editButtonItem;
	
	CommentViewController *commentViewController;

    IBOutlet UIBarButtonItem *approveButton;
    IBOutlet UIBarButtonItem *unapproveButton;
    IBOutlet UIBarButtonItem *spamButton;
    IBOutlet UIBarButtonItem *deleteButton;
    BOOL editing;

    IBOutlet UIView* moderationSwipeView;
    UITableViewCell* moderationSwipeCell;
    UISwipeGestureRecognizerDirection moderationSwipeDirection;
    BOOL animatingRemovalOfModerationSwipeView;

    NSMutableArray *commentsArray;
    NSMutableDictionary *commentsDict;
    NSMutableArray *selectedComments;
    UIAlertView *progressAlert;
    int indexForCurrentPost;
	NSNumber *lastUserSelectedCommentID;
	NSIndexPath *selectedIndexPath;
	NSIndexPath *lastUserSelectedIndexPath;
	
	// added to distinguish a single posts's comments VC
	// from the master VC's comments list.
	// consider rethinking how this is done.
	BOOL isSecondaryViewController;
	
    EGORefreshTableHeaderView *_refreshHeaderView;
}

@property (readonly) UIBarButtonItem *editButtonItem;
@property (nonatomic, retain) NSMutableArray *selectedComments;
@property (nonatomic, retain) NSMutableArray *commentsArray;
@property int indexForCurrentPost; 
@property (nonatomic, retain) NSNumber *lastUserSelectedCommentID;
@property (nonatomic, retain) CommentViewController *commentViewController;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@property (nonatomic, assign) BOOL isSecondaryViewController;
@property (nonatomic, retain) NSFetchedResultsController *resultsController;
@property (nonatomic, retain) Blog *blog;
@property (nonatomic, retain) IBOutlet UIView* moderationSwipeView;
@property (nonatomic, retain) UITableViewCell* moderationSwipeCell;
@property (nonatomic) UISwipeGestureRecognizerDirection moderationSwipeDirection;

- (IBAction)deleteSelectedComments:(id)sender;
- (IBAction)approveSelectedComments:(id)sender;
- (IBAction)unapproveSelectedComments:(id)sender;
- (IBAction)spamSelectedComments:(id)sender;
- (IBAction)replyToSelectedComment:(id)sender;
- (void)refreshCommentsList;
- (void)setIndexForCurrentPost:(int)index;
- (void)showCommentAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark -
#pragma mark Comment navigation

- (BOOL)hasPreviousComment;
- (BOOL)hasNextComment;
- (void)showPreviousComment;
- (void)showNextComment;
- (void)trySelectSomething;
- (void)trySelectSomethingAndShowIt;

@end
