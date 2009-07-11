#import <Foundation/Foundation.h>
#import "RefreshButtonView.h"

@class BlogDataManager, PostViewController, PostDetailEditController, DraftsListController;

@interface PostsListController : UITableViewController <UITableViewDataSource, UITableViewDelegate> {
    UIBarButtonItem *newButtonItem;

    IBOutlet UITableView *postsTableView;

    PostViewController *postDetailViewController;
    PostDetailEditController *postDetailEditController;
    RefreshButtonView *refreshButton;

    BOOL connectionStatus;
}

@property (readonly) UIBarButtonItem *newButtonItem;
@property (nonatomic, retain) PostViewController *postDetailViewController;
@property (nonatomic, retain) PostDetailEditController *postDetailEditController;

@end
