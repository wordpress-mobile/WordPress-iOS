#import <Foundation/Foundation.h>

#import "CoreDataStack.h"

NS_ASSUME_NONNULL_BEGIN

@interface CoreDataService : NSObject

/**
 *  @brief      This `CoreDataStack` object this instance will use for interacting with CoreData.
 */
@property (nonatomic, strong, readonly) id<CoreDataStack> coreDataStack;

/**
 *  @brief      Initializes the instance.
 *
 *  @param      coreDataStack     The `CoreDataStack` this instance will use for interacting with CoreData.
 *                                Cannot be nil.
 *
 *  @returns    The initialized object.
 */
- (instancetype)initWithCoreDataStack:(id<CoreDataStack>)coreDataStack NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
