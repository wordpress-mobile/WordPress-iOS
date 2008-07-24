#import <UIKit/UIKit.h>

@class BlogDataManager, WordPressAppDelegate, BlogDetailModalViewController, PostsListController;

@interface WPBlogsListController : UIViewController <UITableViewDelegate> {

	IBOutlet UIBarButtonItem *addBlogButton;
	
	IBOutlet UITableView	*blogsTableView;
	IBOutlet UIToolbar	*blogsToolbar;
	
	IBOutlet BlogDetailModalViewController *blogDetailViewController;
	IBOutlet PostsListController *postsListController;	
	
}

@property (nonatomic, retain) BlogDetailModalViewController *blogDetailViewController;
@property (nonatomic, retain) PostsListController *postsListController;

@end
