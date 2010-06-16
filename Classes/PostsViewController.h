#import <Foundation/Foundation.h>
#import "RefreshButtonView.h"

#define newPost 0
#define editPost 1
#define autorecoverPost 2
#define refreshPost 3

@class BlogDataManager, PostViewController, EditPostViewController;

@interface PostsViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate> {
@private
    UIBarButtonItem *newButtonItem;
	UIAlertView *progressAlert;
	NSIndexPath *selectedIndexPath;
    PostViewController *postDetailViewController;
    EditPostViewController *postDetailEditController;
    RefreshButtonView *refreshButton;
	BOOL anyMorePosts;
}

@property (readonly) UIBarButtonItem *newButtonItem;
@property (nonatomic, retain) PostViewController *postDetailViewController;
@property (nonatomic, retain) EditPostViewController *postDetailEditController;
@property (nonatomic, assign) BOOL anyMorePosts;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;

- (void)addSpinnerToCell:(NSIndexPath *)indexPath;
- (void)removeSpinnerFromCell:(NSIndexPath *)indexPath;
- (void)loadPosts;
- (void)showAddPostView;
- (void)reselect;

@end
