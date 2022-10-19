#import "TodayExtensionService.h"
#import <NotificationCenter/NotificationCenter.h>
#import "Constants.h"
#import "WordPress-Swift.h"

@implementation TodayExtensionService

- (void)configureTodayWidgetWithSiteID:(NSNumber *)siteID
                              blogName:(NSString *)blogName
                               blogUrl:(NSString *)blogUrl
                          siteTimeZone:(NSTimeZone *)timeZone
                        andOAuth2Token:(NSString *)oauth2Token
{
    NSParameterAssert(siteID != nil);
    NSParameterAssert(blogName != nil);
    NSParameterAssert(timeZone != nil);
    NSParameterAssert(oauth2Token.length > 0);

    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WPAppGroupName];
    
    // If the widget site has changed, clear the widgets saved data.
    NSNumber *previousSiteID = [sharedDefaults objectForKey:AppConfigurationWidget.statsTodayWidgetUserDefaultsSiteIdKey];
    if (siteID != previousSiteID) {
        [StatsDataHelper clearWidgetsData];
        [WPAnalytics track:WPAnalyticsStatWidgetActiveSiteChanged];
    }

    // Save the site information to shared user defaults for use in the today widgets.
    [sharedDefaults setObject:timeZone.name forKey:AppConfigurationWidget.statsTodayWidgetUserDefaultsSiteTimeZoneKey];
    [sharedDefaults setObject:siteID forKey:AppConfigurationWidget.statsTodayWidgetUserDefaultsSiteIdKey];
    [sharedDefaults setObject:blogName forKey:AppConfigurationWidget.statsTodayWidgetUserDefaultsSiteNameKey];
    [sharedDefaults setObject:blogUrl forKey:AppConfigurationWidget.statsTodayWidgetUserDefaultsSiteUrlKey];
    
    NSError *error;
    
    [KeychainUtils.shared storeUsername:AppConfigurationWidget.statsTodayWidgetKeychainTokenKey
                               password:oauth2Token
                            serviceName:AppConfigurationWidget.statsTodayWidgetKeychainServiceName
                            accessGroup:WPAppKeychainAccessGroup
                         updateExisting:YES
                                  error:&error];
    if (error) {
        DDLogError(@"Today Widget OAuth2Token error: %@", error);
    }
}

- (void)removeTodayWidgetConfiguration
{
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WPAppGroupName];

    [sharedDefaults removeObjectForKey:AppConfigurationWidget.statsTodayWidgetUserDefaultsSiteTimeZoneKey];
    [sharedDefaults removeObjectForKey:AppConfigurationWidget.statsTodayWidgetUserDefaultsSiteIdKey];
    [sharedDefaults removeObjectForKey:AppConfigurationWidget.statsTodayWidgetUserDefaultsSiteNameKey];
    [sharedDefaults removeObjectForKey:AppConfigurationWidget.statsTodayWidgetUserDefaultsSiteUrlKey];
    
    [KeychainUtils.shared deleteItemWithUsername:AppConfigurationWidget.statsTodayWidgetKeychainTokenKey
                                     serviceName:AppConfigurationWidget.statsTodayWidgetKeychainServiceName
                                     accessGroup:WPAppKeychainAccessGroup
                                           error:nil];
}

- (BOOL)widgetIsConfigured
{
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WPAppGroupName];
    NSString *siteId = [sharedDefaults stringForKey:AppConfigurationWidget.statsTodayWidgetUserDefaultsSiteIdKey];
    NSString *oauth2Token = [KeychainUtils.shared getPasswordForUsername:AppConfigurationWidget.statsTodayWidgetKeychainTokenKey
                                                             serviceName:AppConfigurationWidget.statsTodayWidgetKeychainServiceName
                                                             accessGroup:WPAppKeychainAccessGroup
                                                                   error:nil];
    
    if (siteId.length == 0 || oauth2Token.length == 0) {
        return NO;
    } else {
        return YES;
    }
}

@end
