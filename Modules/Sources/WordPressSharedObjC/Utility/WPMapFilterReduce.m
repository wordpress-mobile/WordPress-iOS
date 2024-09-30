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

@end
