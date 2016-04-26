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

+ (NSString *)simperiumAppId {
	return @"";
}

+ (NSString *)simperiumAPIKey {
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

+ (NSString *)lookbackToken {
   return @"";
}

+ (NSString *)appbotXAPIKey {
   return @"";
}

+ (NSString *)optimizelyAPIKey {
    return @"";
}

@end
