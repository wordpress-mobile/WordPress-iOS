#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "NSString+XMLExtensions.h" 
#import "WordPressAppDelegate.h"
#import "AboutViewController.h"
#import "BlogViewController.h"
#import "EditBlogViewController.h"
#import "BlogDataManager.h"
#import "Reachability.h"
#import "PostsViewController.h"
#import "WelcomeViewController.h"
#import "WordPressAppDelegate.h"
#import "UIViewController+WPAnimation.h"
#import "Blog.h"
#import "BlogSplitViewMasterViewController.h"
#import "CPopoverManager.h"

@class BlogDataManager, WordPressAppDelegate, EditBlogViewController, BlogViewController;

@interface BlogsViewController : UITableViewController {
}

- (void)showBlog:(BOOL)animated;
- (void)showBlogDetailModalViewForNewBlogWithAnimation:(BOOL)animated;

@end
