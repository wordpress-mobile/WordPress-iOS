#import "DateUtils.h"

@implementation DateUtils

+ (NSDate *)dateFromISOString:(NSString *)dateString
{
    NSArray *formats = @[@"yyyy-MM-dd'T'HH:mm:ssZZZZZ", @"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = nil;
    if ([dateString length] == 25) {
        NSRange rng = [dateString rangeOfString:@":" options:NSBackwardsSearch range:NSMakeRange(20, 5)];
        if (rng.location != NSNotFound) {
            dateString = [dateString stringByReplacingCharactersInRange:rng withString:@""];
        }
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    for (NSString *dateFormat in formats) {
        [dateFormatter setDateFormat:dateFormat];
        date = [dateFormatter dateFromString:dateString];
        if (date){
            return date;
        }
    }
    return date;
}

+ (NSString *)isoStringFromDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    return [dateFormatter stringFromDate:date];
}

@end
