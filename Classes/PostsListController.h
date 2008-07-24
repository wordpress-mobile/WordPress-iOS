#import <UIKit/UIKit.h>

@class BlogDataManager, PostDetailViewController, PostDetailEditController, DraftsListController;

@interface PostsListController : UIViewController {
		
	IBOutlet UIBarButtonItem *syncPostsButton;
	IBOutlet UIBarButtonItem *postsStatusButton;
	
	IBOutlet UITableView *postsTableView;

	PostDetailViewController *postDetailViewController;
	PostDetailEditController *postDetailEditController;
		
	BOOL connectionStatus;
}

@property (nonatomic, retain) PostDetailViewController *postDetailViewController;
@property (nonatomic, retain) PostDetailEditController *postDetailEditController;

- (IBAction)downloadRecentPosts:(id)sender;
- (IBAction)showAddPostView:(id)sender;

@end
