#import <UIKit/UIKit.h>

@class Blog;

@interface BlogListViewController : UIViewController

@property (nonatomic, strong) Blog *selectedBlog;

- (void)setSelectedBlog:(Blog *)selectedBlog animated:(BOOL)animated;

- (void)bypassBlogListViewController;
- (BOOL)shouldBypassBlogListViewControllerWhenSelectedFromTabBar;

@end
