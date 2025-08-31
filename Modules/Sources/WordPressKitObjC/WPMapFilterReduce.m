#import "WPMapFilterReduce.h"

@implementation NSArray (WPKitMapFilterReduce)

- (NSArray *)wpkit_map:(WPKitMapBlock)mapBlock
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

- (NSArray *)wpkit_filter:(WPKitFilterBlock)filterBlock
{
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:self.count];
    for (id obj in self) {
        if (filterBlock(obj)) {
            [results addObject:obj];
        }
    }
    return [NSArray arrayWithArray:results];
}

@end
