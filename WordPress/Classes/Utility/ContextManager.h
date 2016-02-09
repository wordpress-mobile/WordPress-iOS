#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface ContextManager : NSObject

///----------------------------------------------
///@name Persistent Contexts
///
/// The mainContext has concurrency type
/// NSMainQueueConcurrencyType and should be used
/// for UI elements and fetched results controllers.
/// During Simperium startup, a backgroundWriterContext
/// will be created.
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
 Save a derived context created with `newDerivedContext` via this convenience method
 
 @param a derived NSManagedObjectContext constructed with `newDerivedContext` above
*/
- (void)saveDerivedContext:(NSManagedObjectContext *)context;

/**
 Save a derived context created with `newDerivedContext` and optionally execute a completion block.
 Useful for if the guarantee is needed that the data has made it into the main context.
 
 @param a derived NSManagedObjectContext constructed with `newDerivedContext` above
 @param a completion block that will be executed on the main queue
 */
- (void)saveDerivedContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)())completionBlock;

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
- (void)saveContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)())completionBlock;

/**
 Get a peranent NSManagedObjectID for the specified NSManagedObject
 
 @param managedObject A managedObject with a temporary NSManagedObjectID
 @return YES if the permanentID was successfully obtained, or NO if it failed.
 */
- (BOOL)obtainPermanentIDForObject:(NSManagedObject *)managedObject;

/**
  Verify if the Core Data model migration failed.
 
  @return YES if there were any errors during the migration: the PSC instance is mapping to a fresh database.
 */
- (BOOL)didMigrationFail;

@end
