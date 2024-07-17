#import <Foundation/Foundation.h>

typedef id (^WPMapBlock)(id obj);
typedef BOOL (^WPFilterBlock)(id obj);

@interface NSArray (WPMapFilterReduce)

/**
 Transforms values in an array

 The resulting array will include the results of calling mapBlock for each of
 the receiver array objects. If mapBlock returns nil that value will be missing
 from the resulting array.
 */
- (NSArray *)wp_map:(WPMapBlock)mapBlock;

/**
 Filters an array to only include values that satisfy the filter block
 */
- (NSArray *)wp_filter:(WPFilterBlock)filterBlock;

@end
