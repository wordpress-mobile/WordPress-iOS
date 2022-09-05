#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

/// A type that's used to handle how `NSManagedObjectContext` objects are created and how the data in them are saved.
@protocol ManagedObjectContextFactory<NSObject>

- (instancetype)initWithPersistentContainer:(NSPersistentContainer *)container;

@property (nonatomic, readonly, strong) NSManagedObjectContext *mainContext;

- (NSManagedObjectContext *const)newDerivedContext;

- (void)saveContext:(NSManagedObjectContext *)context andWait:(BOOL)wait withCompletionBlock:(void (^_Nullable)(void))completionBlock;

@end

NS_ASSUME_NONNULL_END
