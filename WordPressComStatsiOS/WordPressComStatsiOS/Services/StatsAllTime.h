#import <Foundation/Foundation.h>

@interface StatsAllTime : NSObject

@property (nonatomic, copy) NSString *numberOfPosts;
@property (nonatomic, strong) NSNumber *numberOfPostsValue;
@property (nonatomic, copy) NSString *numberOfViews;
@property (nonatomic, strong) NSNumber *numberOfViewsValue;
@property (nonatomic, copy) NSString *numberOfVisitors;
@property (nonatomic, strong) NSNumber *numberOfVisitorsValue;
@property (nonatomic, copy) NSString *bestNumberOfViews;
@property (nonatomic, strong) NSNumber *bestNumberOfViewsValue;
@property (nonatomic, strong) NSString *bestViewsOn;

@end
