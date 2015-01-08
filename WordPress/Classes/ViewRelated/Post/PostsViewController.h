#import <Foundation/Foundation.h>
#import "WPTableViewController.h"

@class WPPostViewController;

@interface PostsViewController : WPTableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, assign) BOOL anyMorePosts;
@property (nonatomic, strong) NSMutableArray *drafts;

- (void)showAddPostView;
- (BOOL)refreshRequired;

@end
