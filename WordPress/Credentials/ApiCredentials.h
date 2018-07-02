#import <Foundation/Foundation.h>

@interface ApiCredentials : NSObject
+ (NSString *)client;
+ (NSString *)secret;
+ (NSString *)pocketConsumerKey;
+ (NSString *)crashlyticsApiKey;
+ (NSString *)hockeyappAppId;
+ (NSString *)googlePlusClientId;
+ (NSString *)googleLoginClientId;
+ (NSString *)googleLoginServerClientId;
+ (NSString *)debuggingKey;
+ (NSString *)zendeskAppId;
+ (NSString *)zendeskUrl;
+ (NSString *)zendeskClientId;
@end
