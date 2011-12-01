#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <CrashReporter/CrashReporter.h>
#import "Constants.h"
#import "UIDevice-Hardware.h"
#import "Blog.h"
#import "CrashReportViewController.h"
#import "FlurryAnalytics.h"
#import "HelpViewController.h"

@class AutosaveManager;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate> {
	Blog *currentBlog;
@private

    IBOutlet UIWindow *window;
    IBOutlet UINavigationController *navigationController;
	IBOutlet UISplitViewController *splitViewController;
	CrashReportViewController *crashReportView;
    BOOL connectionStatus;
    BOOL alertRunning, passwordAlertRunning;
    BOOL isUploadingPost;
	BOOL isWPcomAuthenticated;

    UIImageView *splashView;
	NSMutableData *statsData;
	NSString *postID;
    UITextField *passwordTextField;
	
	// Core Data
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
    
    //Background tasks
    UIBackgroundTaskIdentifier bgTask;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;
@property (nonatomic, retain) CrashReportViewController *crashReportView;
@property (readonly, nonatomic, retain) UINavigationController *masterNavigationController;
@property (readonly, nonatomic, retain) UINavigationController *detailNavigationController;
@property (nonatomic, getter = isAlertRunning) BOOL alertRunning;
@property (nonatomic, assign) BOOL isWPcomAuthenticated;
@property (nonatomic, assign) BOOL isUploadingPost;
@property (nonatomic, retain) Blog *currentBlog;
@property (nonatomic, retain) NSString *postID;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSString *)applicationDocumentsDirectory;
- (NSString *)applicationUserAgent;
- (NSString *)readerCachePath;

+ (WordPressAppDelegate *)sharedWordPressApp;

- (void)handleCrashReport;
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)showNotificationErrorAlert:(NSNotification *)notification;
- (BOOL)isWPcomAuthenticated;
- (void)checkWPcomAuthentication;
- (void)setAutoRefreshMarkers;
- (void)showContentDetailViewController:(UIViewController *)viewController;
- (void)deleteLocalDraft:(NSNotification *)notification;
- (void)dismissCrashReporter:(NSNotification *)notification;
- (void)sendApnsToken;
- (void)sendApnsTokenInBackground;
- (void)sendPushNotificationBlogsList;
- (void)sendPushNotificationBlogsListInBackground;
- (void)openNotificationScreenWithOptions:(NSDictionary *)remoteNotif;
@end
