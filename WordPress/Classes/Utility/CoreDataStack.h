#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CoreDataStack
@property (nonatomic, readonly, strong) NSManagedObjectContext *mainContext;
- (NSManagedObjectContext *const)newDerivedContext DEPRECATED_MSG_ATTRIBUTE("Use `performAndSave` instead");
- (void)saveContextAndWait:(NSManagedObjectContext *)context;
- (void)saveContext:(NSManagedObjectContext *)context;
- (void)saveContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^ _Nullable)(void))completionBlock onQueue:(dispatch_queue_t)queue NS_SWIFT_NAME(save(_:completion:on:));

/// Execute the given block with a background context and save the changes.
///
/// This function _blocks_ its running thread. The changed made by the `aBlock` argument are saved before this
/// function returns.
///
/// - Parameter aBlock: A closure which uses the given `NSManagedObjectContext` to make Core Data model changes.
- (void)performAndSaveUsingBlock:(void (^)(NSManagedObjectContext *context))aBlock;

/// Execute the given block with a background context and save the changes _if the block does not throw an error_.
///
/// This function _does not block_ its running thread. The `aBlock` argument is executed in the background. The
/// `completion` block is called after the Core Data model changes are saved.
///
/// - Parameters:
///   - aBlock: A block which uses the given `NSManagedObjectContext` to make Core Data model changes.
///   - completion: A closure which is called after the changes made by the `block` are saved.
///   - queue: A queue on which to execute the `completion` block.
- (void)performAndSaveUsingBlock:(void (^)(NSManagedObjectContext *context))aBlock completion:(void (^ _Nullable)(void))completion onQueue:(dispatch_queue_t)queue;

@end

NS_ASSUME_NONNULL_END
