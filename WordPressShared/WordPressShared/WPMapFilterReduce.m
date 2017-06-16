#import "WPMapFilterReduce.h"

@implementation NSArray (WPMapFilterReduce)

- (NSArray *)wp_map:(WPMapBlock)mapBlock
{
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:self.count];
    for (id obj in self) {
        id objectToAdd = mapBlock(obj);
        if (objectToAdd) {
            [results addObject:objectToAdd];
        }
    }
    return [NSArray arrayWithArray:results];
}

- (NSArray *)wp_filter:(WPFilterBlock)filterBlock
{
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:self.count];
    for (id obj in self) {
        if (filterBlock(obj)) {
            [results addObject:obj];
        }
    }
    return [NSArray arrayWithArray:results];
}

- (id)wp_reduce:(WPReduceBlock)reduceBlock withInitialValue:(id)initial
{
    id accumulator = initial;
    for (id obj in self) {
        accumulator = reduceBlock(accumulator, obj);
    }
    return accumulator;
}

@end
