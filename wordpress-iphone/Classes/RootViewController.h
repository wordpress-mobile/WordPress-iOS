#import <UIKit/UIKit.h>
#import "AboutViewController.h"

@class BlogDataManager, WordPressAppDelegate, BlogDetailModalViewController, PostsListController;

@interface RootViewController : UIViewController {
	IBOutlet UITableView *blogsTableView;
	
	IBOutlet PostsListController *postsListController;	
}

@property (nonatomic, retain) PostsListController *postsListController;

@end
