#import <UIKit/UIKit.h>
#import "Constants.h"
#import "UIDevice-Hardware.h"

@class BlogDataManager;
@class CFirstLaunchViewController;
@class WelcomeViewController;


@interface WordPressAppDelegate : NSObject <UIApplicationDelegate> {
@private
    BlogDataManager *dataManager;

    IBOutlet UIWindow *window;
    IBOutlet UINavigationController *navigationController;
	IBOutlet UISplitViewController *splitViewController;
	CFirstLaunchViewController *firstLaunchController;
    BOOL connectionStatus;
    BOOL alertRunning;
	
	WelcomeViewController *welcomeViewController;

    UIImageView *splashView;
	NSMutableData *statsData;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;
@property (readonly, nonatomic, retain) UINavigationController *masterNavigationController;
@property (readonly, nonatomic, retain) UINavigationController *detailNavigationController;
@property (nonatomic, retain) CFirstLaunchViewController *firstLaunchController;
@property (nonatomic, getter = isAlertRunning) BOOL alertRunning;
@property (nonatomic, retain) WelcomeViewController *welcomeViewController;

+ (WordPressAppDelegate *)sharedWordPressApp;

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)showErrorAlert:(NSString *)message;
- (void)storeCurrentBlog;
- (void)resetCurrentBlogInUserDefaults;
- (BOOL)shouldLoadBlogFromUserDefaults;
- (void)setAutoRefreshMarkers;

- (void)showContentDetailViewController:(UIViewController *)viewController;

@end
