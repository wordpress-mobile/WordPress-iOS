#import "WPStatsGroup.h"
#import "NSObject+SafeExpectations.h"

@implementation WPStatsGroup

+ (NSArray *)groupsFromData:(NSArray *)groups {
    NSMutableArray *groupList = [NSMutableArray array];
    for (NSDictionary *group in groups) {
        WPStatsGroup *rg = [[self alloc] init];
        rg.title = [group stringForKey:@"name"];
        rg.iconUrl = [NSURL URLWithString:[group stringForKey:@"icon"]];
        rg.count = [group numberForKey:@"total"];
        [rg addChildrenFromArray:[group arrayForKey:@"results"]];
        [groupList addObject:rg];
    }
    return groupList;
}

- (void)addChildrenFromArray:(NSArray *)results {
    NSMutableArray *children = [NSMutableArray array];
    for (NSArray *c in results) {
        WPStatsTitleCountItem *r = [[WPStatsTitleCountItem alloc] init];
        r.title = c[0];
        r.URL = [NSURL URLWithString:c[0]];
        r.count = c[1];
        [children addObject:r];
    }
    self.children = children;
}

@end
