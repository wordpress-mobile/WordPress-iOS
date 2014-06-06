#import "NSDate+JSON.h"

@implementation NSDate (JSON)

+ (instancetype)dateWithWordPressComJSONString:(NSString *)string {
    static NSDateFormatter *rfc3339DateFormatter;
    if (rfc3339DateFormatter == nil) {
        rfc3339DateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];

        [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
        [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'SSZ"];
        [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    return [rfc3339DateFormatter dateFromString:string];
}

@end
