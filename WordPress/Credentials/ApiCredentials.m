#import "ApiCredentials.h"

#define WPCOM_API_CLIENT_ID @""
#define WPCOM_API_CLIENT_SECRET @""

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
