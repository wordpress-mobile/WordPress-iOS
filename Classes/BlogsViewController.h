#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "NSString+XMLExtensions.h" 
#import "WordPressAppDelegate.h"
#import "BlogViewController.h"
#import "EditSiteViewController.h"
#import "BlogDataManager.h"
#import "MediaManager.h"
#import "Reachability.h"
#import "PostsViewController.h"
#import "WelcomeViewController.h"
#import "WordPressAppDelegate.h"
#import "UIViewController+WPAnimation.h"
#import "Blog.h"
#import "BlogSplitViewMasterViewController.h"
#import "CPopoverManager.h"

@interface BlogsViewController : UITableViewController <UIAccelerometerDelegate, UIAlertViewDelegate> {
	NSMutableArray *blogsList;
	WordPressAppDelegate *appDelegate;
}

@property (nonatomic, retain) NSMutableArray *blogsList;

- (void)showBlog:(BOOL)animated;
- (void)deleteBlog:(NSIndexPath *)indexPath;
- (void)didDeleteBlogSuccessfully:(NSIndexPath *)indexPath;
- (void)showBlogWithoutAnimation;
- (void)edit:(id)sender;
- (void)cancel:(id)sender;
- (BOOL)canChangeCurrentBlog;
- (void)blogsRefreshNotificationReceived:(NSNotification *)notification;

@end
