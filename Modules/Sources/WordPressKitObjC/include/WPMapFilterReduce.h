#import <Foundation/Foundation.h>

typedef id (^WPKitMapBlock)(id obj);
typedef BOOL (^WPKitFilterBlock)(id obj);

@interface NSArray (WPKitMapFilterReduce)

/**
 Transforms values in an array

 The resulting array will include the results of calling mapBlock for each of
 the receiver array objects. If mapBlock returns nil that value will be missing
 from the resulting array.
 */
- (NSArray *)wpkit_map:(WPKitMapBlock)mapBlock;

/**
 Filters an array to only include values that satisfy the filter block
 */
- (NSArray *)wpkit_filter:(WPKitFilterBlock)filterBlock;

@end
