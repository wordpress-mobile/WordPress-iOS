#import <UIKit/UIKit.h>
#import "WPSearchController.h"

@interface BlogListViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIDataSourceModelAssociation, WPSearchResultsUpdating, WPSearchControllerDelegate>

- (void)bypassBlogListViewController;
- (BOOL)shouldBypassBlogListViewControllerWhenSelectedFromTabBar;

@end
