#import <Foundation/Foundation.h>
#import "PostViewController.h"
#import "WPTableViewController.h"

@class EditPostViewController;

@interface PostsViewController : WPTableViewController <UIAccelerometerDelegate, NSFetchedResultsControllerDelegate, DetailViewDelegate>

@property (nonatomic, strong) EditPostViewController *postDetailViewController;
@property (nonatomic, strong) PostViewController *postReaderViewController;
@property (nonatomic, assign) BOOL anyMorePosts;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) NSMutableArray *drafts;

- (void)showAddPostView;
- (void)reselect;
- (BOOL)refreshRequired;

@end
