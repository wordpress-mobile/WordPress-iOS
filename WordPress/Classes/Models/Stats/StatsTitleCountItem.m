#import "StatsTitleCountItem.h"

NSString *const StatsResultsToday = @"today";
NSString *const StatsResultsYesterday = @"yesterday";

@implementation StatsTitleCountItem

+ (NSArray *)titleCountItemsFromData:(NSDictionary *)data {
    NSMutableArray *finalArray = [NSMutableArray array];
    for (NSArray *titleCountArray in data) {
        StatsTitleCountItem *titleCountItem = [[StatsTitleCountItem alloc] initWithData:titleCountArray];
        [finalArray addObject:titleCountItem];
    }
    return finalArray;
}

- (id)initWithData:(NSArray *)data {
    self = [super init];
    if (self) {
        self.title = data[0];
        self.count = data[1];
    }
    return self;
}

@end
