#import <UIKit/UIKit.h>

@class BlogDataManager, PostsListController;
@interface DraftsListController : UITableViewController 
{
	BlogDataManager *dm;
	PostsListController *postsListController;
}
@property (nonatomic, assign) PostsListController *postsListController;
@end
