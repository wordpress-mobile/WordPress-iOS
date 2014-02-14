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
#import "SPAuthenticationConfiguration.h"



@class Simperium;
@class SPBinaryManager;

#if TARGET_OS_IPHONE
@class UIViewController;
#else
@class NSWindow;
#endif

extern NSString * const SimperiumWillSaveNotification;


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

// Initializes Simperium.
#if TARGET_OS_IPHONE
- (id)initWithRootViewController:(UIViewController *)controller;
#else
- (id)initWithWindow:(NSWindow *)aWindow;
#endif


// Starts Simperium with the given credentials (from simperium.com) and an existing Core Data stack.
- (void)startWithAppID:(NSString *)identifier
				APIKey:(NSString *)key
				 model:(NSManagedObjectModel *)model
               context:(NSManagedObjectContext *)context
		   coordinator:(NSPersistentStoreCoordinator *)coordinator;

// Save and sync all changed objects. If you're using Core Data, this is just a convenience method
// (you can also just save your context and Simperium will see the changes).
- (BOOL)save;

// Force Simperium to sync all its buckets. Success return value will be false if the timeout is reached, and the sync wasn't completed.
typedef void (^SimperiumForceSyncCompletion)(BOOL success);
- (void)forceSyncWithTimeout:(NSTimeInterval)timeoutSeconds completion:(SimperiumForceSyncCompletion)completion;

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

// Manual Authentication Mechanism
- (void)authenticateWithToken:(NSString *)token;

// Clears all locally stored data from the device. Can be used to perform a manual sign out.
- (void)signOutAndRemoveLocalData:(BOOL)remove;

// Shares an object with a particular user's email address (forthcoming).
//- (void)shareObject:(SPManagedObject *)object withEmail:(NSString *)email;

// Alternative to setting delegates on each individual bucket (if you want a single handler
// for everything). If you need to, call this after starting Simperium.
- (void)setAllBucketDelegates:(id<SPBucketDelegate>)aDelegate;

// Opens an authentication interface if necessary.
- (BOOL)authenticateIfNecessary;

// Manually adds a binary file to be tracked by Simperium (forthcoming).
- (NSString *)addBinary:(NSData *)binaryData toObject:(SPManagedObject *)object bucketName:(NSString *)bucketName attributeName:(NSString *)attributeName;
- (void)addBinaryWithFilename:(NSString *)filename toObject:(SPManagedObject *)object bucketName:(NSString *)bucketName attributeName:(NSString *)attributeName;

// Set this to true if you need to be able to cancel the authentication dialog.
@property (nonatomic) BOOL authenticationOptional;

// A SimperiumDelegate for system callbacks.
@property (nonatomic, weak) id<SimperiumDelegate> delegate;

// Toggle verbose logging.
@property (nonatomic) BOOL verboseLoggingEnabled;

// Toggle remote logging.
@property (nonatomic) BOOL remoteLoggingEnabled;

// Enables or disables the network.
@property (nonatomic) BOOL networkEnabled;

// Overrides the built-in authentication flow so you can customize the behavior.
@property (nonatomic) BOOL authenticationEnabled;

// Returns the currently authenticated Simperium user.
@property (nonatomic, strong) SPUser *user;

// The full URL used to communicate with Simperium.
@property (nonatomic, readonly, copy) NSString *appURL;

// URL to a Simperium server (can be changed to point to a custom installation).
@property (nonatomic, copy) NSString *rootURL;

// A unique ID for this app (configured at simperium.com).
@property (nonatomic, readonly, copy) NSString *appID;

// An access token for this app (generated at simperium.com).
@property (nonatomic, readonly, copy) NSString *APIKey;

// A hashed, unique ID for this client.
@property (nonatomic, readonly, copy) NSString *clientID;

// Set this if for some reason you want to use multiple Simperium instances (e.g. unit testing).
@property (nonatomic, copy) NSString *label;

// Remote Bucket Name Overrides!
@property (nonatomic, copy) NSDictionary *bucketOverrides;

// You can implement your own subclass of SPAuthenticationViewController (iOS) or
// SPAuthenticationWindowController (OSX) to customize authentication.
#if TARGET_OS_IPHONE
@property (nonatomic, weak) Class authenticationViewControllerClass;
#else
@property (nonatomic, weak) Class authenticationWindowControllerClass;
#endif

@property (nonatomic, strong) SPBinaryManager *binaryManager;

@property (nonatomic, strong) SPAuthenticator *authenticator;


#if TARGET_OS_IPHONE
@property (nonatomic, weak) UIViewController *rootViewController;
#else
@property (nonatomic, weak) NSWindow *window;
#endif

@end
