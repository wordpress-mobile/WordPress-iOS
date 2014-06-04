#import "WPStatsTopPost.h"

@implementation WPStatsTopPost

+ (NSDictionary *)postsFromTodaysData:(NSDictionary *)todaysData yesterdaysData:(NSDictionary *)yesterdaysData {
    NSMutableArray *todayPostList = [NSMutableArray array];
    for (NSDictionary *post in todaysData[@"top-posts"]) {
        WPStatsTopPost *topPost = [[WPStatsTopPost alloc] initTopPost:post];
        [todayPostList addObject:topPost];
    }
    NSMutableArray *yesterdayPostList = [NSMutableArray array];
    for (NSDictionary *post in yesterdaysData[@"top-posts"]) {
        WPStatsTopPost *topPost = [[WPStatsTopPost alloc] initTopPost:post];
        [yesterdayPostList addObject:topPost];
    }

    return @{StatsResultsToday: todayPostList, StatsResultsYesterday: yesterdayPostList};
}

- (id)initTopPost:(NSDictionary *)post {
    self = [super init];
    if (self) {
        self.title = post[@"title"];
        self.URL = [NSURL URLWithString:post[@"url"]];
        self.count = post[@"views"];
    }
    return self;
}

@end
