#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <CrashReporter/CrashReporter.h>
#import "Constants.h"
#import "UIDevice-Hardware.h"
#import "Blog.h"
#import "HelpViewController.h"
#import "Reachability.h"
#import "WPComOAuthController.h"
#import "PanelNavigationController.h"
#import "FBConnect.h"
#import "CrashReportViewController.h"
#import "Constants.h"

@class AutosaveManager;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate, WPComOAuthDelegate, FBSessionDelegate> {
	Blog *currentBlog;
    //Connection Reachability variables
    Reachability *internetReachability;
    Reachability *wpcomReachability;
    Reachability *currentBlogReachability;
    BOOL connectionAvailable, wpcomAvailable, currentBlogAvailable;
    Facebook *facebook;
@private
    IBOutlet UIWindow *window;
    IBOutlet UINavigationController *navigationController;

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
    PanelNavigationController *panelNavigationController;

}

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, getter = isAlertRunning) BOOL alertRunning;
@property (nonatomic, assign) BOOL isWPcomAuthenticated;
@property (nonatomic, assign) BOOL isUploadingPost;
@property (nonatomic, strong) Blog *currentBlog;
@property (nonatomic, strong) NSString *postID;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) Facebook *facebook;
@property (nonatomic, strong) PanelNavigationController *panelNavigationController;

//Connection Reachability variables
@property (nonatomic, strong) Reachability *internetReachability, *wpcomReachability, *currentBlogReachability;
@property (nonatomic, assign) BOOL connectionAvailable, wpcomAvailable, currentBlogAvailable;

- (NSString *)applicationDocumentsDirectory;
- (NSString *)applicationUserAgent;

+ (WordPressAppDelegate *)sharedWordPressApplicationDelegate;

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)showNotificationErrorAlert:(NSNotification *)notification;
- (BOOL)isWPcomAuthenticated;
- (void)checkWPcomAuthentication;
- (void)showContentDetailViewController:(UIViewController *)viewController;
- (void)registerForPushNotifications;
- (void)sendApnsToken;
- (void)unregisterApnsToken;
- (void)openNotificationScreenWithOptions:(NSDictionary *)remoteNotif;
- (void)useDefaultUserAgent;
- (void)useAppUserAgent;

@end
