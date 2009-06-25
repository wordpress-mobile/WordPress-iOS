#import <UIKit/UIKit.h>

@class BlogDataManager, PostPhotosViewController, PostDetailEditController, DraftsListController;

@interface PostsListController : UIViewController {
		
	IBOutlet UIBarButtonItem *syncPostsButton;
	IBOutlet UIBarButtonItem *postsStatusButton;
	
	IBOutlet UITableView *postsTableView;

	PostPhotosViewController *postDetailViewController;
	PostDetailEditController *postDetailEditController;
		
	BOOL connectionStatus;
}

@property (nonatomic, retain) PostPhotosViewController *postDetailViewController;
@property (nonatomic, retain) PostDetailEditController *postDetailEditController;

- (IBAction)downloadRecentPosts:(id)sender;
- (IBAction)showAddPostView:(id)sender;
@end
