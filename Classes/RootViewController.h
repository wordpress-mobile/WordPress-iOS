#import <UIKit/UIKit.h>
#import "AboutViewController.h"

@class BlogDataManager, WordPressAppDelegate, BlogDetailModalViewController, BlogMainViewController;

@interface RootViewController : UIViewController {
	IBOutlet UITableView *blogsTableView;
}

@end