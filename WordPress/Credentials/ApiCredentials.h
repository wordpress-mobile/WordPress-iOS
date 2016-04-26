#import <Foundation/Foundation.h>

@interface ApiCredentials : NSObject
+ (NSString *)client;
+ (NSString *)secret;
+ (NSString *)pocketConsumerKey;
+ (NSString *)mixpanelAPIToken;
+ (NSString *)crashlyticsApiKey;
+ (NSString *)hockeyappAppId;
+ (NSString *)googlePlusClientId;
+ (NSString *)simperiumAppId;
+ (NSString *)simperiumAPIKey;
+ (NSString *)helpshiftAPIKey;
+ (NSString *)helpshiftDomainName;
+ (NSString *)helpshiftAppId;
+ (NSString *)debuggingKey;
+ (NSString *)lookbackToken;
+ (NSString *)appbotXAPIKey;
+ (NSString *)optimizelyAPIKey;
@end
