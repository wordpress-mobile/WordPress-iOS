#import <Foundation/Foundation.h>

typedef id (^WPMapBlock)(id obj);
typedef BOOL (^WPFilterBlock)(id obj);
typedef id (^WPReduceBlock)(id accumulator, id obj);

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

/**
 Combines the array values into a single value

 The reduce block is called for each value. The first time it's sent the initial
 value, and subsequent calls will use the result of the previous call as the
 accumulator.

 For instance, to calculate the sum of all items:
    [array wp_reduce:^id(id accumulator, id obj) {
        return @([accumulator longLongValue] + [obj longLongValue]);
    } withInitialValue:@0];
 */
- (id)wp_reduce:(WPReduceBlock)reduceBlock withInitialValue:(id)initial;

@end
