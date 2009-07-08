#import <Foundation/Foundation.h>

@class BlogDataManager, PostPhotosViewController, PostDetailEditController, DraftsListController;

@interface PostsListController : UITableViewController {
	UIBarButtonItem *newButtonItem;
	
	IBOutlet UITableView *postsTableView;

	PostPhotosViewController *postDetailViewController;
	PostDetailEditController *postDetailEditController;
		
	BOOL connectionStatus;
}

@property (readonly) UIBarButtonItem *newButtonItem;
@property (nonatomic, retain) PostPhotosViewController *postDetailViewController;
@property (nonatomic, retain) PostDetailEditController *postDetailEditController;

@end
