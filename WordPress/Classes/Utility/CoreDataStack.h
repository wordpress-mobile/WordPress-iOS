#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CoreDataStack
@property (nonatomic, readonly, strong) NSManagedObjectContext *mainContext;
- (NSManagedObjectContext *const)newDerivedContext DEPRECATED_MSG_ATTRIBUTE("Use `performAndSave` instead");
- (void)saveContextAndWait:(NSManagedObjectContext *)context;
- (void)saveContext:(NSManagedObjectContext *)context;
- (void)saveContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)(void))completionBlock;
- (void)saveContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)(void))completionBlock onQueue:(dispatch_queue_t)queue;
- (void)performAndSaveUsingBlock:(void (^)(NSManagedObjectContext *context))aBlock;
- (void)performAndSaveUsingBlock:(void (^)(NSManagedObjectContext *context))aBlock completion:(void (^)(void))completion;
- (void)performAndSaveUsingBlock:(void (^)(NSManagedObjectContext *context))aBlock completion:(void (^)(void))completion onQueue:(dispatch_queue_t)queue;
@end

NS_ASSUME_NONNULL_END
