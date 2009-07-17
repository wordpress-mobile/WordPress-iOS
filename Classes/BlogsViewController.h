#import <UIKit/UIKit.h>
#import "AboutViewController.h"

@class BlogDataManager, WordPressAppDelegate, EditBlogViewController, BlogViewController;

@interface BlogsViewController : UITableViewController {
}

- (void)showBlog:(BOOL)animated;
- (void)showBlogDetailModalViewForNewBlogWithAnimation:(BOOL)animated;

@end
