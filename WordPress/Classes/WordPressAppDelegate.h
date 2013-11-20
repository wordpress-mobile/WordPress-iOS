#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "Constants.h"
#import "Blog.h"
#import "Reachability.h"
#import "Constants.h"
#import "DDFileLogger.h"


@class AutosaveManager;
@class NotificationsViewController;
@class ReaderPostsViewController;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate> {
    //Connection Reachability variables
    Reachability *internetReachability;
    Reachability *wpcomReachability;
    Reachability *currentBlogReachability;
    BOOL connectionAvailable, wpcomAvailable, currentBlogAvailable;
@private
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

}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, getter = isAlertRunning) BOOL alertRunning;
@property (nonatomic, assign) BOOL isWPcomAuthenticated;
@property (nonatomic, assign) BOOL isUploadingPost;
@property (nonatomic, strong) Blog *currentBlog;
@property (nonatomic, strong) NSString *postID;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) UITabBarController *tabBarController;
@property (nonatomic, strong) NotificationsViewController *notificationsViewController;
@property (nonatomic, strong) ReaderPostsViewController *readerPostsViewController;
@property (strong, nonatomic) DDFileLogger *fileLogger;


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
- (void)useDefaultUserAgent;
- (void)useAppUserAgent;

- (void)showNotificationsTab;

@end
