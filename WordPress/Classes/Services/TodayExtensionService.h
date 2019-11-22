#import <UIKit/UIKit.h>

@interface TodayExtensionService : NSObject

- (void)configureTodayWidgetWithSiteID:(NSNumber *)siteID
                              blogName:(NSString *)blogName
                               blogUrl:(NSString *)blogUrl
                          siteTimeZone:(NSTimeZone *)timeZone
                        andOAuth2Token:(NSString *)oauth2Token;

- (void)removeTodayWidgetConfiguration;

- (BOOL)widgetIsConfigured;

@end
