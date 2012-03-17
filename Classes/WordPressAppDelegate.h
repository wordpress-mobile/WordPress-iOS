#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <CrashReporter/CrashReporter.h>
#import "Constants.h"
#import "UIDevice-Hardware.h"
#import "Blog.h"
#import "CrashReportViewController.h"
#import "HelpViewController.h"
#import "Reachability.h"
#import "WPComOAuthController.h"

@class AutosaveManager;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate, WPComOAuthDelegate> {
	Blog *currentBlog;
    //Connection Reachability variables
    Reachability *internetReachability;
    Reachability *wpcomReachability;
    Reachability *currentBlogReachability;
    BOOL connectionAvailable, wpcomAvailable, currentBlogAvailable;
@private
    IBOutlet UIWindow *window;
    IBOutlet UINavigationController *navigationController;
	IBOutlet UISplitViewController *splitViewController;
	CrashReportViewController *crashReportView;
    BOOL alertRunning, passwordAlertRunning;
    BOOL isUploadingPost;
	BOOL isWPcomAuthenticated;

	NSMutableData *statsData;
	NSString *postID;
    UITextField *passwordTextField;
    NSString *oauthCallback;
	    
	// Core Data
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
    
    //Background tasks
    UIBackgroundTaskIdentifier bgTask;
    
    // Push notifications
    NSDictionary *lastNotificationInfo;
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

//Connection Reachability variables
@property (nonatomic, retain) Reachability *internetReachability, *wpcomReachability, *currentBlogReachability;
@property (nonatomic, assign) BOOL connectionAvailable, wpcomAvailable, currentBlogAvailable;

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
- (void)sendPushNotificationBlogsList;
- (void)openNotificationScreenWithOptions:(NSDictionary *)remoteNotif;
@end
