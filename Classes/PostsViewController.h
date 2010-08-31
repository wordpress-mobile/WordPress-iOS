#import <Foundation/Foundation.h>
#import "RefreshButtonView.h"
#import "DraftManager.h"
#import "Post.h";

@class BlogDataManager, PostViewController, EditPostViewController;

@interface PostsViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIAccelerometerDelegate> {
@private
    UIBarButtonItem *newButtonItem;
	UIAlertView *progressAlert;
	NSIndexPath *selectedIndexPath;
    PostViewController *postDetailViewController;
    EditPostViewController *postDetailEditController;
    RefreshButtonView *refreshButton;
	DraftManager *draftManager;
	BOOL anyMorePosts;
	
    NSMutableArray *drafts;
}

@property (readonly) UIBarButtonItem *newButtonItem;
@property (nonatomic, retain) PostViewController *postDetailViewController;
@property (nonatomic, retain) EditPostViewController *postDetailEditController;
@property (nonatomic, retain) DraftManager *draftManager;
@property (nonatomic, assign) BOOL anyMorePosts;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) NSMutableArray *drafts;

- (void)addSpinnerToCell:(NSIndexPath *)indexPath;
- (void)removeSpinnerFromCell:(NSIndexPath *)indexPath;
- (void)loadPosts;
- (void)showAddPostView;
- (void)reselect;

@end
