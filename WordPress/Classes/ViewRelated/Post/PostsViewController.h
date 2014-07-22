#import <Foundation/Foundation.h>
#import "AbstractPostsViewController.h"
#import "PostContentView.h"

@class EditPostViewController;

@interface PostsViewController : AbstractPostsViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSMutableArray *drafts;

- (void)showAddPostView;
- (BOOL)refreshRequired;

@end
