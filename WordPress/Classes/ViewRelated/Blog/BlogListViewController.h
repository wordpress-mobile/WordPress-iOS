#import <UIKit/UIKit.h>

@class Blog;

@interface BlogListViewController : UIViewController

@property (nonatomic, strong) Blog *selectedBlog;

- (void)bypassBlogListViewController;
- (BOOL)shouldBypassBlogListViewControllerWhenSelectedFromTabBar;

@end
