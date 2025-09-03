#import <Foundation/Foundation.h>

@interface WPKitDateUtils : NSObject

+ (NSDate *)dateFromISOString:(NSString *)isoString;
+ (NSString *)isoStringFromDate:(NSDate *)date;

@end
