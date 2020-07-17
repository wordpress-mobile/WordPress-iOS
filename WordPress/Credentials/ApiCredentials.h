#import <Foundation/Foundation.h>

@interface ApiCredentials : NSObject
+ (NSString *)client;
+ (NSString *)secret;
+ (NSString *)sentryDSN;
+ (NSString *)appCenterAppId;
+ (NSString *)googleLoginClientId;
+ (NSString *)googleLoginSchemeId;
+ (NSString *)googleLoginServerClientId;
+ (NSString *)debuggingKey;
+ (NSString *)zendeskAppId;
+ (NSString *)zendeskUrl;
+ (NSString *)zendeskClientId;
+ (NSString *)tenorApiKey;
+ (NSString *)encryptedLogKey;
@end
