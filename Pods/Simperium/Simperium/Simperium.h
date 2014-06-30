//
//  Simperium.h
//
//  Created by Michael Johnston on 11-02-11.
//  Copyright 2011 Simperium. All rights reserved.
//
//  A simple system for shared state. See http://simperium.com for details.

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SPBucket.h"
#import "SPManagedObject.h"
#import "SPAuthenticator.h"
#import "SPUser.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIApplication.h>
#endif


@class Simperium;

#if TARGET_OS_IPHONE
@class UIViewController;
#else
@class NSWindow;
#endif


#pragma mark ====================================================================================
#pragma mark Simperium Constants
#pragma mark ====================================================================================

extern NSString * const SimperiumWillSaveNotification;

typedef NS_ENUM(NSInteger, SPSimperiumErrors) {
	SPSimperiumErrorsMissingAppID,
	SPSimperiumErrorsMissingAPIKey,
	SPSimperiumErrorsMissingToken,
	SPSimperiumErrorsMissingWindow
};


#pragma mark ====================================================================================
#pragma mark SimperiumDelegate
#pragma mark ====================================================================================

/**	You can use this delegate to respond to general events and errors.
	If you want explicit callbacks when objects are changed/added/deleted, you can also use SPBucketDelegate in SPBucket.h. 
	Standard Core Data notifications are also generated, allowing you to update a `UITableView` (for example) in your `NSFetchedResultsControllerDelegate`.
 */
@protocol SimperiumDelegate <NSObject>
@optional
- (void)simperium:(Simperium *)simperium didFailWithError:(NSError *)error;
- (void)simperiumDidLogin:(Simperium *)simperium;
- (void)simperiumDidLogout:(Simperium *)simperium;
- (void)simperiumDidCancelLogin:(Simperium *)simperium;
@end


#pragma mark ====================================================================================
#pragma mark Simperium: The main class through which you access Simperium.
#pragma mark ====================================================================================

@interface Simperium : NSObject

// Initializes Simperium: After executing this method, your CoreData Stack will be fully initialized
- (id)initWithModel:(NSManagedObjectModel *)model
			context:(NSManagedObjectContext *)context
		coordinator:(NSPersistentStoreCoordinator *)coordinator;

// Initializes Simperium: This constructor allows you to specify custom mappings between local and remote buckets.
- (id)initWithModel:(NSManagedObjectModel *)model
			context:(NSManagedObjectContext *)context
		coordinator:(NSPersistentStoreCoordinator *)coordinator
			  label:(NSString *)label
    bucketOverrides:(NSDictionary *)bucketOverrides;

#if TARGET_OS_IPHONE
// Starts Simperium and displays the auth interface, if needed.
- (void)authenticateWithAppID:(NSString *)identifier APIKey:(NSString *)key rootViewController:(UIViewController *)controller;
#else
// Starts Simperium and displays the auth interface, if needed.
- (void)authenticateWithAppID:(NSString *)identifier APIKey:(NSString *)key window:(NSWindow *)aWindow;
#endif

// Starts Simperium with a given token, with no UI interaction required.
- (void)authenticateWithAppID:(NSString *)identifier token:(NSString *)token;


#pragma mark ====================================================================================
#pragma mark Public Methods
#pragma mark ====================================================================================

// Save and sync all changed objects. If you're using Core Data, this is just a convenience method
// (you can also just save your context and Simperium will see the changes).
- (BOOL)save;

// Support for iOS Background Fetch. 'result' flag will be set to UIBackgroundFetchResultNewData, if new data was retrieved,
// or set to UIBackgroundFetchResultNoData in any other case.
#if defined(__IPHONE_7_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0)
typedef void (^SimperiumBackgroundFetchCompletion)(UIBackgroundFetchResult result);
- (void)backgroundFetchWithCompletion:(SimperiumBackgroundFetchCompletion)completion;
#endif

// Get a particular bucket (which, for Core Data, corresponds to a particular Entity name in your model).
// Once you have a bucket instance, you can set a SPBucketDelegate to react to changes.
- (SPBucket *)bucketForName:(NSString *)name;

// Convenience methods for accessing the Core Data stack.
- (NSManagedObjectContext *)managedObjectContext;
- (NSManagedObjectContext *)writerManagedObjectContext;
- (NSManagedObjectModel *)managedObjectModel;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;


// OTHER

// Saves without syncing (typically not used).
- (BOOL)saveWithoutSyncing;

#if !TARGET_OS_IPHONE
// Support for OSX delayed app termination: Ensure local changes have a chance to fully save
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
#endif

// Clears all locally stored data from the device. Can be used to perform a manual sign out.
// Note: This method is now asynchronous. Please, listen to signout delegate calls, or implement a completion callback block.
typedef void (^SimperiumSignoutCompletion)(void);
- (void)signOutAndRemoveLocalData:(BOOL)remove completion:(SimperiumSignoutCompletion)completion;

// Shares an object with a particular user's email address (forthcoming).
//- (void)shareObject:(SPManagedObject *)object withEmail:(NSString *)email;

// Alternative to setting delegates on each individual bucket (if you want a single handler
// for everything). If you need to, call this after starting Simperium.
- (void)setAllBucketDelegates:(id<SPBucketDelegate>)aDelegate;

// Opens an authentication interface if necessary.
- (BOOL)authenticateIfNecessary;

// A SimperiumDelegate for system callbacks.
@property (nonatomic, readwrite, weak) id<SimperiumDelegate> delegate;

// Set this to true if you need to be able to cancel the authentication dialog.
@property (nonatomic, readwrite, assign) BOOL authenticationOptional;

// Toggle verbose logging.
@property (nonatomic, readwrite, assign) BOOL verboseLoggingEnabled;

// Toggle remote logging.
@property (nonatomic, readwrite, assign) BOOL remoteLoggingEnabled;

// Enables or disables the network.
@property (nonatomic, readwrite, assign) BOOL networkEnabled;

// Returns the currently authenticated Simperium user.
@property (nonatomic, readonly, strong) SPUser *user;

// The full URL used to communicate with Simperium.
@property (nonatomic, readonly, copy) NSString *appURL;

// URL to a Simperium server (can be changed to point to a custom installation).
@property (nonatomic, readwrite, copy) NSString *rootURL;

// A unique ID for this app (configured at simperium.com).
@property (nonatomic, readonly, copy) NSString *appID;

// An access token for this app (generated at simperium.com).
@property (nonatomic, readonly, copy) NSString *APIKey;

// A hashed, unique ID for this client.
@property (nonatomic, readonly, copy) NSString *clientID;

// Remote Bucket Name Overrides!
@property (nonatomic, readonly, copy) NSDictionary *bucketOverrides;

// Returns the current SPAuthenticator instance
@property (nonatomic, readwrite, strong) SPAuthenticator *authenticator;

// Returns a flag indicating if there is network access
@property (nonatomic, readonly, assign) BOOL requiresConnection;

// Returns a string describing the network status
@property (nonatomic, readonly, strong) NSString *networkStatus;

// Returns the timestamp of the last message received by the backend
@property (nonatomic, readonly, strong) NSDate *networkLastSeenTime;


// You can implement your own subclass of SPAuthenticationViewController (iOS) or
// SPAuthenticationWindowController (OSX) to customize authentication.
#if TARGET_OS_IPHONE
@property (nonatomic, readwrite, weak) Class authenticationViewControllerClass;
#else
@property (nonatomic, readwrite, weak) Class authenticationWindowControllerClass;
#endif

#if TARGET_OS_IPHONE
@property (nonatomic, readwrite, weak) UIViewController *rootViewController;
#else
@property (nonatomic, readwrite, weak) NSWindow *window;
#endif

@end
