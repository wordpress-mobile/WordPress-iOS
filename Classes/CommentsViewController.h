//
//  CommentsViewControllers.h
//  WordPress
//
//  Created by Janakiram on 02/09/08.
//

#import <Foundation/Foundation.h>

#import "CommentsTableViewDelegate.h"
#import "WPTableViewController.h"
#import "Blog.h"
#import "ReplyToCommentViewController.h"

@class CommentViewController;

@interface CommentsViewController : WPTableViewController <ReplyToCommentViewControllerDelegate, UIAccelerometerDelegate, CommentsTableViewDelegate> {
@private
    IBOutlet UITableView *commentsTableView;

    IBOutlet UIToolbar *editToolbar;
    UIBarButtonItem *editButtonItem;
	
	CommentViewController *commentViewController;
    
    IBOutlet UIBarButtonItem *approveButton;
    IBOutlet UIBarButtonItem *unapproveButton;
    IBOutlet UIBarButtonItem *spamButton;
    IBOutlet UIBarButtonItem *deleteButton;
	BOOL replying;
	BOOL willReloadTable;

    UITableViewCell* moderationSwipeCell;
    UISwipeGestureRecognizerDirection moderationSwipeDirection;
    BOOL animatingRemovalOfModerationSwipeView;

    NSMutableArray *commentsArray;
    NSMutableDictionary *commentsDict;
    int indexForCurrentPost;
	NSNumber *lastUserSelectedCommentID;
	NSIndexPath *selectedIndexPath, *selectionWanted;
		
	NSDate *dateOfPreviouslyOldestComment;
}

@property (readonly) UIBarButtonItem *editButtonItem;
@property (nonatomic, retain) NSMutableArray *commentsArray;
@property int indexForCurrentPost; 
@property (nonatomic, retain) NSNumber *lastUserSelectedCommentID;
@property (nonatomic, retain) CommentViewController *commentViewController;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) NSFetchedResultsController *resultsController;
@property (nonatomic, retain) Blog *blog;
@property (nonatomic, retain) IBOutlet UIButton *moderationApproveButton, *moderationSpamButton, *moderationReplyButton;
@property (nonatomic, retain) UITableViewCell* moderationSwipeCell;
@property (nonatomic) UISwipeGestureRecognizerDirection moderationSwipeDirection;
@property (nonatomic, retain) NSDate *dateOfPreviouslyOldestComment;

- (IBAction)deleteSelectedComments:(id)sender;
- (IBAction)approveSelectedComments:(id)sender;
- (IBAction)unapproveSelectedComments:(id)sender;
- (IBAction)spamSelectedComments:(id)sender;
- (IBAction)replyToSelectedComment:(id)sender;
- (void)setIndexForCurrentPost:(int)index;
- (void)showCommentAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark -
#pragma mark Comment navigation

- (BOOL)hasPreviousComment;
- (BOOL)hasNextComment;
- (void)showPreviousComment;
- (void)showNextComment;

@end
