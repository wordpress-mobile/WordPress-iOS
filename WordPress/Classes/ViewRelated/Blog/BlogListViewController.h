#import <UIKit/UIKit.h>

@interface BlogListViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIDataSourceModelAssociation>

- (void)bypassBlogListViewController;
- (BOOL)shouldBypassBlogListViewControllerWhenSelectedFromTabBar;

@end
