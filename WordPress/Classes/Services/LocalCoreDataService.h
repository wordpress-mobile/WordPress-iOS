#import <Foundation/Foundation.h>

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
