#import "WPTableViewController.h"

@class AbstractPostTableViewCell;

@interface AbstractPostsViewController : WPTableViewController

@property (nonatomic, strong) AbstractPostTableViewCell *cellForLayout;

@end
