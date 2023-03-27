#import <UIKit/UIKit.h>

@interface TodayExtensionService : NSObject

- (void)configureTodayWidgetOAuth2Token:(NSString *)oauth2Token;

- (void)configureTodayWidgetWithSiteID:(NSNumber *)siteID
                              blogName:(NSString *)blogName
                               blogUrl:(NSString *)blogUrl
                          siteTimeZone:(NSTimeZone *)timeZone;

- (void)removeTodayWidgetConfiguration;

- (BOOL)widgetIsConfigured;

@end
