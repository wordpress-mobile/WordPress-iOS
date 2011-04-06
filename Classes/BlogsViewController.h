#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "NSString+XMLExtensions.h" 
#import "WordPressAppDelegate.h"
#import "BlogViewController.h"
#import "EditSiteViewController.h"
#import "WPReachability.h"
#import "PostsViewController.h"
#import "WelcomeViewController.h"
#import "WordPressAppDelegate.h"
#import "UIViewController+WPAnimation.h"
#import "Blog.h"
#import "CPopoverManager.h"
#import "WPAsynchronousImageView.h"

@interface BlogsViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIAccelerometerDelegate, UIAlertViewDelegate> {
	WordPressAppDelegate *appDelegate;
    NSFetchedResultsController *resultsController;
    Blog *currentBlog;
    UIButton *quickPhotoButton;
}

@property (nonatomic, retain) NSFetchedResultsController *resultsController;
@property (nonatomic, retain) Blog *currentBlog;

- (void)showBlog:(Blog *)blog animated:(BOOL)animated;
- (void)showBlogWithoutAnimation;
- (void)edit:(id)sender;
- (void)cancel:(id)sender;
- (BOOL)canChangeBlog:(Blog *)blog;
- (void)blogsRefreshNotificationReceived:(NSNotification *)notification;
- (void)checkEditButton;
- (void)quickPhotoPost;

@end
