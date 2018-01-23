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
+ (NSString *)firebaseAPIKey;
+ (NSString *)firebaseAppID;
+ (NSString *)helpshiftAPIKey;
+ (NSString *)helpshiftDomainName;
+ (NSString *)helpshiftAppId;
+ (NSString *)debuggingKey;
@end
