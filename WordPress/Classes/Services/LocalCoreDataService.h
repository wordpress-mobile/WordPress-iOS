#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LocalCoreDataService : NSObject

/**
 *  @brief      The context this object will use for interacting with CoreData.
 */
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;

/**
 *  @brief      Initializes the instance.
 *
 *  @param      context     The context this instance will use for interacting with CoreData.
 *                          Cannot be nil.
 *
 *  @returns    The initialized object.
 */
- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context;

@end

NS_ASSUME_NONNULL_END
