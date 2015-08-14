#import <Foundation/Foundation.h>

typedef id (^WPMapBlock)(id obj);
typedef BOOL (^WPFilterBlock)(id obj);
typedef id (^WPReduceBlock)(id accumulator, id obj);

@interface NSArray (WPMapFilterReduce)
- (instancetype)wp_map:(WPMapBlock)mapBlock;
- (instancetype)wp_filter:(WPFilterBlock)filterBlock;
- (id)wp_reduce:(WPReduceBlock)reduceBlock withInitialValue:(id)initial;
@end