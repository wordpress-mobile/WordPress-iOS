#import <UIKit/UIKit.h>

@class Blog;

@interface CalypsoPostsViewController : UITableViewController

@property (nonatomic, strong) Blog *blog;

+ (instancetype)controllerWithBlog:(Blog *)blog;

@end
