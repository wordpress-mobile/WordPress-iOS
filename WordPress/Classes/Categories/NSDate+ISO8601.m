#import "NSDate+ISO8601.h"

@implementation NSDate (ISO8601)

+ (instancetype)dateWithISO8601String:(NSString *)string
{
    static NSDateFormatter *iso8601DateFormatter;
    if (iso8601DateFormatter == nil) {
        iso8601DateFormatter            = [[NSDateFormatter alloc] init];
        iso8601DateFormatter.locale     = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        iso8601DateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
        
        [iso8601DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    
    return [iso8601DateFormatter dateFromString:string];
}

@end
