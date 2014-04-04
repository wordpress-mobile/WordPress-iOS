#import <Foundation/Foundation.h>

@interface WordPressComApiCredentials : NSObject
+ (NSString *)client;
+ (NSString *)secret;
+ (NSString *)pocketConsumerKey;
+ (NSString *)mixpanelAPIToken;
+ (NSString *)crashlyticsApiKey;
+ (NSString *)hockeyappAppId;
+ (NSString *)googlePlusClientId;
@end
