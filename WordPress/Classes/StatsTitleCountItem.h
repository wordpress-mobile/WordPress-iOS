#import <Foundation/Foundation.h>


extern NSString *const StatsResultsToday;
extern NSString *const StatsResultsYesterday;

@interface StatsTitleCountItem : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSNumber *count;
@property (nonatomic, strong) NSURL *URL;

+ (NSArray *)titleCountItemsFromData:(NSDictionary *)data;

@end
