#import <Foundation/Foundation.h>

@class BlogDataManager, PostPhotosViewController, PostDetailEditController, DraftsListController;

@interface PostsListController : UITableViewController {
		
	IBOutlet UITableView *postsTableView;

	PostPhotosViewController *postDetailViewController;
	PostDetailEditController *postDetailEditController;
		
	BOOL connectionStatus;
}

@property (nonatomic, retain) PostPhotosViewController *postDetailViewController;
@property (nonatomic, retain) PostDetailEditController *postDetailEditController;

@end
