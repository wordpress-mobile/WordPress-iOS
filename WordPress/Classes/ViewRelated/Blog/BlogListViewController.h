#import <UIKit/UIKit.h>
#import "WPSearchController.h"

@interface BlogListViewController : UIViewController <NSFetchedResultsControllerDelegate,
                                                            UIDataSourceModelAssociation,
                                                            WPSearchResultsUpdating,
                                                            WPSearchControllerDelegate,
                                                            UITableViewDelegate,
                                                            UITableViewDataSource>

- (void)bypassBlogListViewController;
- (BOOL)shouldBypassBlogListViewControllerWhenSelectedFromTabBar;

@end
