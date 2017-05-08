#import <Foundation/Foundation.h>
#import "StatsStreakItem.h"

@interface StatsStreak : NSObject <NSCopying>

@property (nonatomic, strong) NSNumber *longestStreakLength;
@property (nonatomic, strong) NSDate   *longestStreakStartDate;
@property (nonatomic, strong) NSDate   *longestStreakEndDate;

@property (nonatomic, strong) NSNumber *currentStreakLength;
@property (nonatomic, strong) NSDate   *currentStreakStartDate;
@property (nonatomic, strong) NSDate   *currentStreakEndDate;

@property (nonatomic, strong) NSArray<StatsStreakItem *> *items;

@property (nonatomic, assign) BOOL errorWhileRetrieving;

- (void)pruneItemsOutsideOfMonth:(NSDate*)date;

@end
