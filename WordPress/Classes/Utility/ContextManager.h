#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CoreDataStack
@property (nonatomic, readonly, strong) NSManagedObjectContext *mainContext;
@property (nonatomic, readonly, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly, strong) NSManagedObjectModel *managedObjectModel;
- (NSManagedObjectContext *const)newDerivedContext;
- (NSManagedObjectContext *const)newMainContextChildContext;
- (void)saveContextAndWait:(NSManagedObjectContext *)context;
- (void)saveContext:(NSManagedObjectContext *)context;
- (void)saveContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)(void))completionBlock;
@end

@interface ContextManager : NSObject <CoreDataStack>

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
+ (instancetype)internalSharedInstance;


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

@end

NS_ASSUME_NONNULL_END
