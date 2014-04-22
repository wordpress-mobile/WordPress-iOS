#import "WordPressComApiCredentials.h"

#define WPCOM_API_CLIENT_ID @""
#define WPCOM_API_CLIENT_SECRET @""

@implementation WordPressComApiCredentials
+ (NSString *)client {
    return WPCOM_API_CLIENT_ID;
}

+ (NSString *)secret {
    return WPCOM_API_CLIENT_SECRET;
}

+ (NSString *)mixpanelAPIToken {
    return @"";
}

+ (NSString *)pocketConsumerKey {
    return @"";
}

+ (NSString *)crashlyticsApiKey {
    return @"";
}
    
+ (NSString *)hockeyappAppId {
    return @"";
}
    
+ (NSString *)googlePlusClientId {
    return @"";
}

+ (NSString *)helpshiftAPIKey {
    return  @"";
}

+ (NSString *)helpshiftDomainName {
    return @"";
}

+ (NSString *)helpshiftAppId {
    return @"";
}

+ (NSString *)taplyticsAPIKey {
    return @"";
}

@end
