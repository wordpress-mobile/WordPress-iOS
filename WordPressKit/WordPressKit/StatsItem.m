#import "StatsItem.h"

@interface StatsItem ()

@property (nonatomic, readwrite, weak) StatsItem *parent;

@end

@implementation StatsItem

- (instancetype)init
{
    self = [super init];
    if (self) {
        _children = [NSMutableArray new];
    }
    return self;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"StatsItem - itemID: %@, label: %@, value: %@", self.itemID, self.label, self.value];
}


- (void)addChildStatsItem:(StatsItem *)statsItem
{
    statsItem.parent = self;
    [self.children addObject:statsItem];
}

- (NSUInteger)numberOfRows
{
    NSUInteger itemCount = 1;
    
    if (self.isExpanded == NO) {
        return 1;
    }
    
    for (StatsItem *item in self.children) {
        itemCount += [item numberOfRows];
    }
    
    return itemCount;
}


- (NSUInteger)depth
{
    if (self.parent) {
        return self.parent.depth + 1;
    }
    
    return 1;
}


@end
