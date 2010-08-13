#import <Foundation/Foundation.h>
#import "RefreshButtonView.h"
#import "Post.h";

#define newPost 0
#define editPost 1
#define autorecoverPost 2
#define refreshPost 3

@class BlogDataManager, PostViewController, EditPostViewController;

@interface PostsViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIAccelerometerDelegate> {
@private
    UIBarButtonItem *newButtonItem;
	UIAlertView *progressAlert;
	NSIndexPath *selectedIndexPath;
    PostViewController *postDetailViewController;
    EditPostViewController *postDetailEditController;
    RefreshButtonView *refreshButton;
	BOOL anyMorePosts;
	
    NSMutableArray *drafts;
}

@property (readonly) UIBarButtonItem *newButtonItem;
@property (nonatomic, retain) PostViewController *postDetailViewController;
@property (nonatomic, retain) EditPostViewController *postDetailEditController;
@property (nonatomic, assign) BOOL anyMorePosts;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) NSMutableArray *drafts;

- (void)addSpinnerToCell:(NSIndexPath *)indexPath;
- (void)removeSpinnerFromCell:(NSIndexPath *)indexPath;
- (void)loadPosts;
- (void)showAddPostView;
- (void)reselect;
- (void)fetchDrafts;

@end
