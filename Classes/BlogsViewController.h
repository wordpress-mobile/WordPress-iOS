#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "NSString+XMLExtensions.h" 
#import "WordPressAppDelegate.h"
#import "BlogViewController.h"
#import "EditSiteViewController.h"
#import "PostsViewController.h"
#import "WelcomeViewController.h"
#import "WordPressAppDelegate.h"
#import "Blog.h"
#import "CPopoverManager.h"
#import "QuickPhotoButton.h"
#import "QuickPhotoUploadProgressController.h"
#import "WPReaderViewController.h"
#import "StackScrollViewController.h"

@interface BlogsViewController : UIViewController <NSFetchedResultsControllerDelegate, UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate> {
	WordPressAppDelegate *appDelegate;
    NSFetchedResultsController *resultsController;
    Blog *currentBlog;
    QuickPhotoButton *quickPhotoButton, *readerButton;
    QuickPhotoUploadProgressController *uploadController;
    Post *quickPicturePost;
    UILabel *uploadLabel;
    IBOutlet UITableView *tableView;
    WPReaderViewController *readerViewController;
    BOOL isTransitioning;
    StackScrollViewController *stackScrollViewController;
}

@property (nonatomic, retain) NSFetchedResultsController *resultsController;
@property (nonatomic, retain) Blog *currentBlog;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) StackScrollViewController *stackScrollViewController;

- (void)showBlog:(Blog *)blog animated:(BOOL)animated;
- (void)showBlogWithoutAnimation;
- (void)edit:(id)sender;
- (void)cancel:(id)sender;
- (BOOL)canChangeBlog:(Blog *)blog;
- (void)blogsRefreshNotificationReceived:(NSNotification *)notification;
- (void)checkEditButton;
- (void)quickPhotoPost;
- (void)uploadQuickPhoto:(Post *)post;
- (void)showQuickPhotoButton:(BOOL)delay;

@end
