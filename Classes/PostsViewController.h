#import <Foundation/Foundation.h>
#import "RefreshButtonView.h"

@class BlogDataManager, PostViewController, EditPostViewController;

@interface PostsViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate> {
@private
    UIBarButtonItem *newButtonItem;

//    IBOutlet UITableView *postsTableView;

    PostViewController *postDetailViewController;
    EditPostViewController *postDetailEditController;
    RefreshButtonView *refreshButton;
}

@property (readonly) UIBarButtonItem *newButtonItem;
@property (nonatomic, retain) PostViewController *postDetailViewController;
@property (nonatomic, retain) EditPostViewController *postDetailEditController;

@end
