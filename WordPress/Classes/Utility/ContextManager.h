#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A constant representing the current version of the data model.

 @see -[ContextManager initWithModelName:storeURL:]
 */
FOUNDATION_EXTERN NSString * const ContextManagerModelNameCurrent;

@protocol CoreDataStack
@property (nonatomic, readonly, strong) NSManagedObjectContext *mainContext;
- (NSManagedObjectContext *const)newDerivedContext;
- (void)saveContextAndWait:(NSManagedObjectContext *)context;
- (void)saveContext:(NSManagedObjectContext *)context;
- (void)saveContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)(void))completionBlock;
- (void)performAndSaveUsingBlock:(void (^)(NSManagedObjectContext *context))aBlock;
- (void)performAndSaveUsingBlock:(void (^)(NSManagedObjectContext *context))aBlock completion:(void (^)(void))completion;
@end

@interface ContextManager : NSObject <CoreDataStack>

/**
 The URL for creating an in-memory database.

 @see -[ContextManager initWithModelName:storeURL:]
 */
@property (class, nonatomic, readonly) NSURL *inMemoryStoreURL;

///----------------------------------------------
///@name Persistent Contexts
///
/// The mainContext has concurrency type NSMainQueueConcurrencyType and should be used
/// for UI elements and fetched results controllers.
/// Internally, we'll use a privateQueued context to perform disk write Operations.
///
///----------------------------------------------
@property (nonatomic, readonly, strong) NSManagedObjectContext *mainContext;

///--------------------------------------
///@name ContextManager
///--------------------------------------

/**
 Returns the singleton
 
 @return instance of ContextManager
*/
+ (instancetype)internalSharedInstance;

/**
 Create a ContextManager instance with given model name and database location.

 Note: This initialiser is only used for testing purpose at the moment.

 @param modelName Model name in Core Data data model file.
                  Use ContextManagerModelNameCurrent for current version, or
                  "WordPress <version>" for specific version.
 @param storeURL Database location. Use +[ContextManager inMemoryStoreURL] to create an in-memory database.
 */
- (instancetype)initWithModelName:(NSString *)modelName storeURL:(NSURL *)storeURL NS_DESIGNATED_INITIALIZER;


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
