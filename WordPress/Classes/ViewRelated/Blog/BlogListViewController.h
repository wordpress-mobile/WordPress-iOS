#import <UIKit/UIKit.h>
#import "WPSearchController.h"
#import "WPSearchControllerConfigurator.h"

@interface BlogListViewController : UIViewController <NSFetchedResultsControllerDelegate,
                                                            UIDataSourceModelAssociation,
                                                            WPSearchControllerWithResultsUpdatingDelegate,
                                                            UITableViewDelegate,
                                                            UITableViewDataSource>

- (void)bypassBlogListViewController;
- (BOOL)shouldBypassBlogListViewControllerWhenSelectedFromTabBar;

@end
