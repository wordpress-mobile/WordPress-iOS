#import "WPMapFilterReduce.h"

@implementation NSArray (WPMapFilterReduce)

- (instancetype)wp_map:(id (^)(id obj))mapBlock
{
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:self.count];
    for (id obj in self) {
        id objectToAdd = mapBlock(obj);
        if (objectToAdd) {
            [results addObject:objectToAdd];
        }
    }
    return [[self class] arrayWithArray:results];
}

- (instancetype)wp_filter:(BOOL (^)(id obj))filterBlock
{
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:self.count];
    for (id obj in self) {
        if (filterBlock(obj)) {
            [results addObject:obj];
        }
    }
    return [[self class] arrayWithArray:results];
}

- (id)wp_reduce:(id (^)(id accumulator, id obj))reduceBlock withInitialValue:(id)initial
{
    id accumulator = initial;
    for (id obj in self) {
        accumulator = reduceBlock(accumulator, obj);
    }
    return accumulator;
}

@end