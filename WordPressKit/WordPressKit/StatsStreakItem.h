#import <Foundation/Foundation.h>

@interface StatsStreakItem : NSObject <NSCopying>

@property (nonatomic, copy)   NSString *value;
@property (nonatomic, copy)   NSString *timeStamp;
@property (nonatomic, readonly) NSDate   *date;

@end
