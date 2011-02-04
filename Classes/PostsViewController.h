#import <Foundation/Foundation.h>
#import "RefreshButtonView.h"
#import "MediaManager.h"
#import "Post.h"
#import "PostViewController.h"
#import "EGORefreshTableHeaderView.h"

@class BlogDataManager, EditPostViewController, EditPostViewController;

@interface PostsViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIAccelerometerDelegate, NSFetchedResultsControllerDelegate, EGORefreshTableHeaderDelegate> {
@private
	UIAlertView *progressAlert;
    RefreshButtonView *refreshButton;
    EGORefreshTableHeaderView *_refreshHeaderView;
    UIActivityIndicatorView *activityFooter;
}

@property (readonly) UIBarButtonItem *newButtonItem;
@property (nonatomic, retain) EditPostViewController *postDetailViewController;
@property (nonatomic, retain) PostViewController *postReaderViewController;
@property (nonatomic, retain) MediaManager *mediaManager;
@property (nonatomic, assign) BOOL anyMorePosts;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) NSMutableArray *drafts;
@property (nonatomic, retain) NSFetchedResultsController *resultsController;
@property (nonatomic, retain) Blog *blog;

- (void)addSpinnerToCell:(NSIndexPath *)indexPath;
- (void)removeSpinnerFromCell:(NSIndexPath *)indexPath;
- (void)showAddPostView;
- (void)reselect;

@end
