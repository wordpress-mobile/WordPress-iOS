#import "StatsTitleCountItem.h"

@interface StatsTopPost : StatsTitleCountItem

@property (nonatomic, strong) NSNumber *postID;

+ (NSDictionary *)postsFromTodaysData:(NSDictionary *)todaysData yesterdaysData:(NSDictionary *)yesterdaysData;

@end
