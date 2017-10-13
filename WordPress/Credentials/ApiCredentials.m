#import "ApiCredentials.h"

#define WPCOM_API_CLIENT_ID @"55461"
#define WPCOM_API_CLIENT_SECRET @"vq0sXhkNojad6JHUnH3SsouG0eWJye5m6W4VJxgaj3eXAxZAWA6zJ5QeaPFG6XNx"

@implementation ApiCredentials

+ (NSString *)client {
    return WPCOM_API_CLIENT_ID;
}

+ (NSString *)secret {
    return WPCOM_API_CLIENT_SECRET;
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

+ (NSString *)googleLoginClientId {
    return @"";
}

+ (NSString *)googleLoginServerClientId {
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

+ (NSString *)debuggingKey {
    return @"";
}

@end
