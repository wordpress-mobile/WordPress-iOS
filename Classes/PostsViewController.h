#import <Foundation/Foundation.h>
#import "Post.h"
#import "PostViewController.h"
#import "EGORefreshTableHeaderView.h"

@class EditPostViewController, EditPostViewController;

@interface PostsViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIAccelerometerDelegate, NSFetchedResultsControllerDelegate, EGORefreshTableHeaderDelegate> {
@private
	UIAlertView *progressAlert;
    EGORefreshTableHeaderView *_refreshHeaderView;
    UIActivityIndicatorView *activityFooter;
}

@property (readonly) UIBarButtonItem *composeButtonItem;
@property (nonatomic, retain) EditPostViewController *postDetailViewController;
@property (nonatomic, retain) PostViewController *postReaderViewController;
@property (nonatomic, assign) BOOL anyMorePosts;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) NSMutableArray *drafts;
@property (nonatomic, retain) NSFetchedResultsController *resultsController;
@property (nonatomic, retain) Blog *blog;

- (void)showAddPostView;
- (void)reselect;
- (BOOL)refreshRequired;

@end
