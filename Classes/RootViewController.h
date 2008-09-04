#import <UIKit/UIKit.h>
#import "AboutViewController.h"

@class BlogDataManager, WordPressAppDelegate, BlogDetailModalViewController, BlogMainViewController;

@interface RootViewController : UIViewController {
	IBOutlet UITableView *blogsTableView;
	IBOutlet BlogMainViewController *blogMainViewController;	
}

@property (nonatomic, retain) BlogMainViewController *blogMainViewController;

@end