@interface DateUtils : NSObject

+ (NSDate *)dateFromISOString:(NSString *)isoString;
+ (NSString *)isoStringFromDate:(NSDate *)date;

@end
