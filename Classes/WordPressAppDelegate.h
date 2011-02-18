#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <CrashReporter/CrashReporter.h>
#import "Constants.h"
#import "UIDevice-Hardware.h"
#import "Blog.h"
#import "CrashReportViewController.h"
#import "FlurryAPI.h"

@class BlogDataManager, AutosaveManager;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate> {
	Blog *currentBlog;
@private
    BlogDataManager *dataManager;

    IBOutlet UIWindow *window;
    IBOutlet UINavigationController *navigationController;
	IBOutlet UISplitViewController *splitViewController;
	CrashReportViewController *crashReportView;
    BOOL connectionStatus;
    BOOL alertRunning;
	BOOL isWPcomAuthenticated;

    UIImageView *splashView;
	NSMutableData *statsData;
	NSString *postID;
	
	// Core Data
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;
@property (nonatomic, retain) CrashReportViewController *crashReportView;
@property (readonly, nonatomic, retain) UINavigationController *masterNavigationController;
@property (readonly, nonatomic, retain) UINavigationController *detailNavigationController;
@property (nonatomic, getter = isAlertRunning) BOOL alertRunning;
@property (nonatomic, assign) BOOL isWPcomAuthenticated;
@property (nonatomic, retain) Blog *currentBlog;
@property (nonatomic, retain) NSString *postID;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSString *)applicationDocumentsDirectory;

+ (WordPressAppDelegate *)sharedWordPressApp;

- (void)handleCrashReport;
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)showErrorAlert:(NSString *)message;
- (void)showNotificationErrorAlert:(NSNotification *)notification;
- (void)storeCurrentBlog;
- (void)resetCurrentBlogInUserDefaults;
- (BOOL)shouldLoadBlogFromUserDefaults;
- (BOOL)isWPcomAuthenticated;
- (void)checkWPcomAuthentication;
- (void)setAutoRefreshMarkers;
- (void)showContentDetailViewController:(UIViewController *)viewController;
- (void)syncBlogs;
- (void)syncBlogCategoriesAndStatuses;
- (void)syncTick:(NSTimer *)timer;
- (void)startSyncTimer;
- (void)startSyncTimerThread;
- (void)deleteLocalDraft:(NSNotification *)notification;
- (void)dismissCrashReporter:(NSNotification *)notification;

@end
