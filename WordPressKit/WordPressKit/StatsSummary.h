#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, StatsPeriodUnit) {
    StatsPeriodUnitDay,
    StatsPeriodUnitWeek,
    StatsPeriodUnitMonth,
    StatsPeriodUnitYear
};

typedef NS_ENUM(NSInteger, StatsSummaryType) {
    StatsSummaryTypeViews,
    StatsSummaryTypeVisitors,
    StatsSummaryTypeLikes,
    StatsSummaryTypeComments
};

@interface StatsSummary : NSObject

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) StatsPeriodUnit periodUnit;
@property (nonatomic, copy)   NSString *label;
@property (nonatomic, strong) NSString *views;
@property (nonatomic, strong) NSString *visitors;
@property (nonatomic, strong) NSString *likes;
@property (nonatomic, strong) NSString *comments;

@property (nonatomic, strong) NSNumber *viewsValue;
@property (nonatomic, strong) NSNumber *visitorsValue;
@property (nonatomic, strong) NSNumber *likesValue;
@property (nonatomic, strong) NSNumber *commentsValue;

@end
