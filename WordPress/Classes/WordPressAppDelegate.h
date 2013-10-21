#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "Constants.h"
#import "Blog.h"
#import "Reachability.h"
#import "PanelNavigationController.h"
#import "Constants.h"
#import "DDFileLogger.h"


@class AutosaveManager;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate> {
	Blog *currentBlog;
    //Connection Reachability variables
    Reachability *internetReachability;
    Reachability *wpcomReachability;
    Reachability *currentBlogReachability;
    BOOL connectionAvailable, wpcomAvailable, currentBlogAvailable;
@private
    IBOutlet UIWindow *window;
    IBOutlet UINavigationController *navigationController;

    BOOL alertRunning, passwordAlertRunning;
    BOOL isUploadingPost;
	BOOL isWPcomAuthenticated;

	NSMutableData *statsData;
	NSString *postID;
    UITextField *passwordTextField;
	    
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
@property (nonatomic, strong) PanelNavigationController *panelNavigationController;
@property (strong, nonatomic) DDFileLogger *fileLogger;


//Connection Reachability variables
@property (nonatomic, strong) Reachability *internetReachability, *wpcomReachability, *currentBlogReachability;
@property (nonatomic, assign) BOOL connectionAvailable, wpcomAvailable, currentBlogAvailable;

- (NSString *)applicationUserAgent;

+ (WordPressAppDelegate *)sharedWordPressApplicationDelegate;

+ (void)wipeAllKeychainItems;
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)showNotificationErrorAlert:(NSNotification *)notification;
- (BOOL)isWPcomAuthenticated;
- (void)checkWPcomAuthentication;
- (void)showContentDetailViewController:(UIViewController *)viewController;
- (void)registerForPushNotifications;
- (void)unregisterApnsToken;
- (void)openNotificationScreenWithOptions:(NSDictionary *)remoteNotif;
- (void)useDefaultUserAgent;
- (void)useAppUserAgent;

@end
