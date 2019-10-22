#import "ApiCredentials.h"

#define WPCOM_API_CLIENT_ID @"67049"
#define WPCOM_API_CLIENT_SECRET @"cldvYBF6uHjcoI5QQmszQiSKyeHc1AtXB8tHhy9tRLcOqcCWWvLRfHdh7oyVth2YPZ"

@implementation ApiCredentials

+ (NSString *)client {
    return WPCOM_API_CLIENT_ID;
}

+ (NSString *)secret {
    return WPCOM_API_CLIENT_SECRET;
}

+ (NSString *)sentryDSN {
    return @"";
}
    
+ (NSString *)hockeyappAppId {
    return @"";
}

+ (NSString *)googleLoginClientId {
    return @"";
}

+ (NSString *)googleLoginSchemeId {
    return @"";
}

+ (NSString *)googleLoginServerClientId {
    return @"";
}

+ (NSString *)debuggingKey {
    return @"";
}
+ (NSString *)zendeskAppId {
    return @"";
}
+ (NSString *)zendeskUrl {
    return @"";
}
+ (NSString *)zendeskClientId {
    return @"";
}

@end
