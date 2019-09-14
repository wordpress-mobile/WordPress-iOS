#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface ContextManager : NSObject

///----------------------------------------------
///@name Persistent Contexts
///
/// The mainContext has concurrency type NSMainQueueConcurrencyType and should be used
/// for UI elements and fetched results controllers.
/// Internally, we'll use a privateQueued context to perform disk write Operations.
///
///----------------------------------------------
@property (nonatomic, readonly, strong) NSManagedObjectContext *mainContext;

///-------------------------------------------------------------
///@name Access to the persistent store and managed object model
///-------------------------------------------------------------
@property (nonatomic, readonly, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly, strong) NSManagedObjectModel *managedObjectModel;

///--------------------------------------
///@name ContextManager
///--------------------------------------

/**
 Returns the singleton
 
 @return instance of ContextManager
*/
+ (instancetype)sharedInstance;


///--------------------------
///@name Contexts
///--------------------------

/**
 For usage as a 'scratch pad' context or for doing background work.
 
 Make sure to save using saveDerivedContext:
 
 @return a new MOC with NSPrivateQueueConcurrencyType, 
 with the parent context as the main context
*/
- (NSManagedObjectContext *const)newDerivedContext;

/**
 For usage as a snapshot of the main context. This is useful when operations 
 should happen on the main queue (fetches) but not immedately reflect changes to
 the main context.

 Make sure to save using saveContext:

 @return a new MOC with NSMainQueueConcurrencyType,
 with the parent context as the main context
 */
- (NSManagedObjectContext *const)newMainContextChildContext;

/**
 Save a given context synchronously.
 
 @param a NSManagedObject context instance
 */
- (void)saveContextAndWait:(NSManagedObjectContext *)context;

/**
 Save a given context. Convenience for error handling.
 
 @param a NSManagedObject context instance
 */
- (void)saveContext:(NSManagedObjectContext *)context;

/**
 Save a given context.
 
 @param a NSManagedObject context instance
 @param a completion block that will be executed on the main queue
 */
- (void)saveContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)(void))completionBlock;

/**
 Get a permanent NSManagedObjectID for the specified NSManagedObject
 
 @param managedObject A managedObject with a temporary NSManagedObjectID
 @return YES if the permanentID was successfully obtained, or NO if it failed.
 */
- (BOOL)obtainPermanentIDForObject:(NSManagedObject *)managedObject;

/**
 Merge changes for a given context with a fault-protection, on the context's queue.

 @param context a NSManagedObject context instance
 @return notification NSNotification from a NSManagedObjectContextDidSaveNotification.
 */
- (void)mergeChanges:(NSManagedObjectContext *)context fromContextDidSaveNotification:(NSNotification *)notification;

/**
  Verify if the Core Data model migration failed.
 
  @return YES if there were any errors during the migration: the PSC instance is mapping to a fresh database.
 */
- (BOOL)didMigrationFail;

@end

NS_ASSUME_NONNULL_END
