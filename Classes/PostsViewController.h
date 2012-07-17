#import <Foundation/Foundation.h>
#import "PostViewController.h"
#import "WPTableViewController.h"

@class EditPostViewController;

@interface PostsViewController : WPTableViewController <UIAccelerometerDelegate, NSFetchedResultsControllerDelegate, DetailViewDelegate> {
@private
    UIActivityIndicatorView *activityFooter;
}

@property (nonatomic, retain) EditPostViewController *postDetailViewController;
@property (nonatomic, retain) PostViewController *postReaderViewController;
@property (nonatomic, assign) BOOL anyMorePosts;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) NSMutableArray *drafts;

- (void)showAddPostView;
- (void)reselect;
- (BOOL)refreshRequired;

@end
