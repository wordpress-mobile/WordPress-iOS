#import "WPStatsTitleCountItem.h"

@interface WPStatsTopPost : WPStatsTitleCountItem

@property (nonatomic, strong) NSNumber *postID;

+ (NSDictionary *)postsFromTodaysData:(NSDictionary *)todaysData yesterdaysData:(NSDictionary *)yesterdaysData;

@end
