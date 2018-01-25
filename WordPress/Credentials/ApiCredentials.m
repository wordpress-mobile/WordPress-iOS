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

+ (NSString *)firebaseAPIKey {
    return @"";
}

+ (NSString *)firebaseAppID {
    return @"";
}

+ (NSString *)firebaseGCMID {
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
