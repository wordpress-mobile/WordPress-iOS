#import <UIKit/UIKit.h>
#import "WPSearchController.h"


@interface BlogListViewController : UITableViewController

- (void)bypassBlogListViewController;
- (BOOL)shouldBypassBlogListViewControllerWhenSelectedFromTabBar;

@end
