#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Constants.h"
#import "UIDevice-Hardware.h"

@class BlogDataManager;
@class CFirstLaunchViewController;
@class WelcomeViewController;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate> {
	NSString *selectedBlogID;
	NSDate *lastBlogSync;
@private
    BlogDataManager *dataManager;

    IBOutlet UIWindow *window;
    IBOutlet UINavigationController *navigationController;
	IBOutlet UISplitViewController *splitViewController;
	CFirstLaunchViewController *firstLaunchController;
    BOOL connectionStatus;
    BOOL alertRunning;
	BOOL isWPcomAuthenticated;
	WelcomeViewController *welcomeViewController;

    UIImageView *splashView;
	NSMutableData *statsData;
	
	// Core Data
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;
@property (readonly, nonatomic, retain) UINavigationController *masterNavigationController;
@property (readonly, nonatomic, retain) UINavigationController *detailNavigationController;
@property (nonatomic, retain) CFirstLaunchViewController *firstLaunchController;
@property (nonatomic, getter = isAlertRunning) BOOL alertRunning;
@property (nonatomic, retain) WelcomeViewController *welcomeViewController;
@property (nonatomic, assign) BOOL isWPcomAuthenticated;
@property (nonatomic, retain) NSString *selectedBlogID;
@property (nonatomic, retain) NSDate *lastBlogSync;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSString *)applicationDocumentsDirectory;

+ (WordPressAppDelegate *)sharedWordPressApp;

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)showErrorAlert:(NSString *)message;
- (void)storeCurrentBlog;
- (void)resetCurrentBlogInUserDefaults;
- (BOOL)shouldLoadBlogFromUserDefaults;
- (BOOL)isWPcomAuthenticated;
- (void)checkWPcomAuthentication;
- (void)setAutoRefreshMarkers;
- (void)showContentDetailViewController:(UIViewController *)viewController;
- (void)syncBlogs;

@end
