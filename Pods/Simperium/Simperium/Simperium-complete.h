//
//  Simperium.h
//
//  Created by Michael Johnston on 11-02-11.
//  Copyright 2011 Simperium. All rights reserved.
//
//  A simple system for shared state. See http://simperium.com for details.

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SPStorageObserver.h"

@class SPManagedObject;
@class SPEntityDefinition;
@class SPBinaryManager;
@class SPUser;

#if TARGET_OS_IPHONE
    @class UIViewController;
#else
    @class NSWindow;
#endif

extern NSString * const host;

/** Delegate protocol for sync notifications.
 
 You can use SimperiumDelegate if you want explicit callbacks when entities are changed or added. Standard Core Data notifications are also generated, allowing you to update a `UITableView` (for example) in your `NSFetchedResultsControllerDelegate`.
 
 There are authentication callbacks too.
 */

@protocol SimperiumDelegate <NSObject>
@optional
-(void)objectKeysChanged:(NSSet *)keyArray entityName:(NSString *)entityName;
-(void)objectKeysAdded:(NSSet *)keyArray entityName:(NSString *)entityName;
-(void)objectKeyAcknowledged:(NSString *)key entityName:(NSString *)entityName;
-(void)objectKeyWillBeDeleted:(NSString *)key entityName:(NSString *)entityName;
-(void)objectKeysWillChange:(NSSet *)keyArray entityName:(NSString *)entityName;
-(void)indexingWillStart:(NSString *)entityName;
-(void)indexingDidFinish:(NSString *)entityName;
-(void)authenticationSuccessful;
-(void)authenticationFailed;
-(void)authenticationCanceled;
-(void)lightweightMigrationPerformed;
-(void)receivedObjectForKey:(NSString *)key version:(NSString *)version data:(NSDictionary *)data;
@end

/** The main class through which you access Simperium.
 */
@interface Simperium : NSObject <SPStorageObserver> {
    SPUser *user;
    NSDictionary *bucketOverrides;
	NSString *appURL;
	NSString *clientID;
    NSString *appID;
    NSString *accessKey;
    NSString *iconFilename;
    NSString *label;
    
    SPBinaryManager *binaryManager;
    
#if TARGET_OS_IPHONE
    UIViewController *rootViewController;
#else
    NSWindow *window;
#endif
}


///---------------------------------------------------------------------------------------
/// @name Initialization and Starting the Service
///---------------------------------------------------------------------------------------

/** Initializes Simperium with the given delegate.
 
 This is the designated initializer.
 
 @param delegate An instance that will receive callbacks according to the SimperiumDelegate protocol.
 @param controller The controller that Simperium will use when it needs to display an authentication dialog.
 @param filename The name of an icon file that will be displayed in the authentication dialog. This can just be your app's standard icon file.
 @return Returns initialized instance or `nil` if initialization fails.
 @see SimperiumDelegate
 */
#if TARGET_OS_IPHONE
-(id)initWithDelegate:(id<SimperiumDelegate>)delegate rootViewController:(UIViewController *)controller iconFilename:(NSString *)filename;
#else
-(id)initWithDelegate:(id<SimperiumDelegate>)delegate window:(NSWindow *)aWindow iconFilename:(NSString *)filename;
#endif


/** Starts Simperium with the given application name, access key, and Core Data model name.
 
 When you start Simperium using this method, your Core Data stack is created and managed for you. If you'd prefer to create and manage it yourself, use startWithAppName:accessKey:model:context:coordinator: instead.
 
 @param appName An application name that is set when you create your app at simperium.com.
 @param key The access token that is configured inside your app management panel at simperium.com.
 @param modelName The name of an .xcdatamodeld file that is usually generated when you create your Core Data project. Just provide the prefix, not the extension.
 */
-(void)startWithAppName:(NSString *)appName accessKey:(NSString *)key modelName:(NSString *)modelName;


/** Starts Simperium with the given application name, access key, and an existing Core Data stack.
 
 When you start Simperium using this method, you're responsible for creating/managing your own Core Data stack and passing it to Simperium here. If you'd like Simperium to manage the complexity of Core Data for you instead, use startWithAppName:accessKey:modelName:.
 
 @param appName An application name that is set when you create your app at simperium.com.
 @param key The access token that is configured inside your app management panel at simperium.com.
 @param model A Core Data model to load.
 @param context The main Core Data context you use for your app's data.
 @param coordinator Your app's Core Data coordinator.
 */
-(void)startWithAppName:(NSString *)appName accessKey:(NSString *)key model:(NSManagedObjectModel *)model context:(NSManagedObjectContext *)context coordinator:(NSPersistentStoreCoordinator *)coordinator;


/** Same as startWithKey:modelName: but allows you to manually specify which data you want to sync using a special plist file. The format for this file isn't documented yet.
 @param appName Same as startWithAppName:accessKey:modelName:.
 @param key Same as startWithAppName:accessKey:modelName:.
 @param modelName Same as startWithAppName:accessKey:modelName:.
 @param definitionFile A special plist file that specifies which entities and members to sync. Not yet documented.
 */
-(void)startWithAppName:(NSString *)appName accessKey:(NSString *)key modelName:(NSString *)modelName definitionFile:(NSString *)definitionFile;

/** Adds a delegate so it will be sent notification callbacks.
 
 Simperium maintains a list of delegates that all receive notifications when data is synced. This is subject to change in the future.
 
 @param delegate An instance that will receive callbacks according to the SimperiumDelegate protocol.
 @see SimperiumDelegate
 */
-(void)addDelegate:(id)delegate;

/** Removes a delegate so it no longer receives notification callbacks.
 
 Simperium maintains a list of delegates that all receive notifications when data is synced. This is subject to change in the future.
 
 @param delegate An instance that was previously sent to addDelegate:.
 @see SimperiumDelegate
 */
-(void)removeDelegate:(id)delegate;

///---------------------------------------------------------------------------------------
/// @name Managing Entities
///---------------------------------------------------------------------------------------

/** Creates, configures, and returns a new instance of the class with the specified name.
 
 This method is what you should use to create new instances of your objects. When you create a new object in this way, it won't be saved or synced until you call save or saveAndSync:.
 
 @param entityName The name of an SPManagedObject subclass.
 @return A new, autoreleased, fully configured instance of the class for the entity named entityName.
 @see SPManagedObject
 */
-(id)insertNewObjectForEntityForName:(NSString *)entityName;


/** Creates, configures, and returns a new instance of the class with the specified name using a specific key.
 
 Same as insertNewObjectForEntityForName: but allows you to specify a particular key. Using a particular key can be useful if you have some existing data that you know is unique, for example email addresses, or if you want a single instance for easy access (like for a config class). The new object won't be saved or synced until you call saveAndSync:.
 
 @param entityName The name of an SPManagedObject subclass.
 @param key An identifier that is unique across all instances of the given entityName.
 @return A new, autoreleased, fully configured instance of the class for the entity named entityName.
 */
-(id)insertNewObjectForEntityForName:(NSString *)entityName simperiumKey:(NSString *)key;

/** Specifies an object that should be deleted.
 
 The specified object will be deleted from Core Data and Simperium will stop managing it. The deletion happens immediately and will be synced immediately. While there is currently no way to manually batch a large number of deletions together (let us know if you need this for some reason), Simperium tries to automatically batch them together to reduce network overhead.
 
 @param entity An entity to delete.
 */
-(void)deleteAndSyncObject:(SPManagedObject *)entity;

/** Returns an object that has the specified sync key.
 
 This is a convenience method if you want to get an entity instance that has a particular sync key.
 
 @param key An identifier that is unique across any given entity class. These keys are used to globally identify a particular instance. They're usually automatically created when you call insertNewObjectForEntityForName: but you can also specify your own using insertNewObjectForEntityForName:simperiumKey:.
 @return An entity instance if the key is found, or `nil` otherwise.
 @see SPManagedObject
 */
-(SPManagedObject *)objectForKey:(NSString *)key entityName:(NSString *)entityName;

/** Returns an array of objects for the specified sync keys.
 
 This is a convenience method if you want to get entity instances that have particular sync keys. Useful in conjunction with SimperiumDelegate notifications.
 
 @param keys A set of identifiers that are unique across any given entity class. These keys are used to globally identify a particular instance. They're usually automatically created when you call insertNewObjectForEntityForName: but you can also specify your own using insertNewObjectForEntityForName:simperiumKey:.
 @return An array of object instances for each key that is found.
 @see SPManagedObject
 */
-(NSArray *)objectsForKeys:(NSSet *)keys entityName:(NSString *)entityName;


/** Returns an array containing all instances of a particular entity.
 
 This is a convenience method for getting an array of all entity instances. It's useful if you need to perform some kind of processing, for example a manual sort.
 @param entityName The name of an SPManagedObject subclass whose array of instances should be returned.
 @return An array of entity instances for the given class.
 */
-(NSArray *)objectsForEntityName:(NSString *)entityName;

/** Efficiently returns the number of objects for a particular entity.
 @param entityName The name of an SPManagedObject subclass whose object instances should be counted.
 @param predicate Optional predicate to confine the search. Can be nil.
 @return The number of object instances of the given entityName.
 */
-(NSInteger)numObjectsForEntityName:(NSString *)entityName predicate:(NSPredicate *)predicate;


/** Save and sync all changed entities.
 
 Save and sync all entities that have unsaved changes.
 
 @return `YES` if the context was saved successfully, `NO` otherwise (critical error). It's possible that `YES` will be returned even though a sync does not occur, for example due to a network error. Simperium handles all network errors automatically, so no action is required as long as `YES` is returned. 
 */
-(BOOL)saveAndSync;

// Saves the context directly (typically not used).
-(BOOL)save;

// Saves without syncing (typically not used).
-(BOOL)saveWithoutSyncing;


///---------------------------------------------------------------------------------------
/// @name Sharing
///---------------------------------------------------------------------------------------

/** Shares an object with a particular user's email address

 @param object An object to share.
 @param email The address of a user with whom to share the object.
 */
-(void)shareObject:(SPManagedObject *)object withEmail:(NSString *)email;



///---------------------------------------------------------------------------------------
/// @name Accessing Versions
///---------------------------------------------------------------------------------------

/** Retrieve past versions of data for a particular object.
 
 You can allow your users to access past versions of their data. Call this method to start retrieving past versions. As they load, versionLoaded will be called on delegates.
 
 @param object An object whose past versions should be retrieved.
 @param entityName The name of an SPManagedObject subclass whose versions should be retrieved.
 @param numVersions The number of versions to be retrieved.
 */
-(void)getVersions:(int)numVersions forObject:(SPManagedObject *)object;

///---------------------------------------------------------------------------------------
/// @name Adding and Retrieving Binary Data
///---------------------------------------------------------------------------------------

/** Add some binary data to Simperium.
 
 Simperium has experimental support for storing and syncing binary data. You're welcome to try it but it will probably not work 100% yet. See the Simplecom sample to see how it's currently used. This is subject to change.
 
 @param binaryData Any kind of data.
 @param object The object with which this data is associated.
 @param className The name of the entity class of this object.
 @param memberName The name of the variable that stores the filename associated with this object.
 @return A local filename where the data will be stored. You can store this for later retrieval of the data via getBinary:.
 */
-(NSString *)addBinary:(NSData *)binaryData toObject:(SPManagedObject *)object className:(NSString *)className memberName:(NSString *)memberName;

/** Adds an existing binary file to Simperium by referencing a particular file.
 
 @param filename The filename (full path) for an existing binary file.
 @param object The object with which this data is associated.
 @param className The name of the entity class of this object.
 @param memberName The name of the variable that stores the filename associated with this object.
 */
-(void)addBinaryWithFilename:(NSString *)filename toObject:(SPManagedObject *)object className:(NSString *)className memberName:(NSString *)memberName;

/** Returns binary data that is stored with Simperium.
 
 After a call to addBinary: you'll be able to retrieve that data using the filename that was returned.
 
 @param filename The filename previously returned from a call to addBinary:.
 @return The data that was stored.
 */
-(NSData *)getBinary:(NSString *)filename;

///---------------------------------------------------------------------------------------
/// @name Authentication
///---------------------------------------------------------------------------------------

-(BOOL)authenticateIfNecessary;


///---------------------------------------------------------------------------------------
/// @name Helper Methods
///---------------------------------------------------------------------------------------

/** Enables or disables the network.
 
 If you need to support enabling or disabling network transmissions (for example, if you provide this option to your users), you can call setNetworkEnabled: at any time. Simperium will gracefully cancel all current requests and pick up where it left off next time the network is enabled.
 
 The network is enabled by default.
 
 @param enabled A Boolean value indicating whether the network should be enabled (`YES`) or not (`NO`).
 */
-(void)setNetworkEnabled:(BOOL)enabled;


/** Overrides the built-in authentication flow so you can customize the interface.
 
 Simperium provides a built-in interface that will automatically display when authentication is needed. We'll be working to improve the appearance of this default interface.
 
 If you want to manage your own authentication flow, you can call enableManualAuthentication. Manual authentication is typically achieved by implementing the authenticationSuccessful and authenticationFailed callbacks in SimperiumDelegate. You can supply your own nib file when you present an SPAuthViewController (or subclass). The Simplecom sample shows how to do this.
 
 Note that customization of the web-based OAuth interface is limited. You can provide your app's name and icon when you setup your app at simperium.com (but this is not yet implemented). Please let us know if further customization is important to you.
 
 @see SimperiumDelegate
 @see SPAuthViewController
 */
-(void)enableManualAuthentication;
-(void)setAuthenticationEnabled:(BOOL)enabled;

/// Clears all locally stored data from Simperium. Can be used to perform a manual sign out.
-(void)clearLocalData;

-(NSString *)bucketOverrideForEntityName:(NSString *)entityName;
-(void)setBucketOverrides:(NSDictionary *)bucketOverrides;

/// Set this if for some reason you want to use multiple Simperium instances (e.g. unit testing).
@property (copy) NSString *label;

/** Returns the currently authenticated Simperium user.
 
 Authentication is currently disabled, so this isn't available yet.
 
 @see SPUser
 */
@property (nonatomic,strong) SPUser *user;

///---------------------------------------------------------------------------------------
/// @name Getting the Simperium App Details
///---------------------------------------------------------------------------------------

/// The full URL used to communicate with Simperium.
@property (nonatomic,copy,readonly) NSString *appURL;

/// A unique ID for this client (usually a hashed UUID).
@property (nonatomic, readonly) NSString *clientID;

/// A unique ID for this app (configured at simperium.com).
@property (nonatomic,readonly) NSString *appID;

/// An access token for this app (generated at simperium.com)
@property (nonatomic, readonly) NSString *accessKey;

#if TARGET_OS_IPHONE
@property (nonatomic, weak) UIViewController *rootViewController;
#else
@property (nonatomic, weak) NSWindow *window;
#endif

@property (nonatomic, copy) NSString *iconFilename;


///---------------------------------------------------------------------------------------
/// @name Getting the Core Data Instances
///---------------------------------------------------------------------------------------

/// The NSManagedObjectContext used by Simperium.
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;

/// The NSManagedObjectModel used by Simperium.
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;

/// The NSPersistentStoreCoordinator used by Simperium.
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

// Not intended to be accessed directly
@property (nonatomic, strong) SPBinaryManager *binaryManager;
@property (nonatomic,weak,readonly) NSMutableSet *delegates;


@end
