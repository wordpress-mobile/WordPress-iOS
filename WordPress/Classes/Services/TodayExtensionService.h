#import <UIKit/UIKit.h>

@interface TodayExtensionService : NSObject

- (void)configureTodayWidgetWithSiteID:(NSNumber *)siteID blogName:(NSString *)blogName siteTimeZone:(NSTimeZone *)timeZone andOAuth2Token:(NSString *)oauth2Token;
- (void)removeTodayWidgetConfiguration;
- (void)hideTodayWidgetIfNotConfigured;

- (BOOL)widgetIsConfigured;

@end
