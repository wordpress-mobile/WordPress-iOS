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
    NSNumber *previousSiteID = [sharedDefaults objectForKey:AppConfigurationWidgetStatsToday.userDefaultsSiteIdKey];
    if (siteID != previousSiteID) {
        [StatsDataHelper clearWidgetsData];
        [WPAnalytics track:WPAnalyticsStatWidgetActiveSiteChanged];
    }

    // Save the site information to shared user defaults for use in the today widgets.
    [sharedDefaults setObject:timeZone.name forKey:AppConfigurationWidgetStatsToday.userDefaultsSiteTimeZoneKey];
    [sharedDefaults setObject:siteID forKey:AppConfigurationWidgetStatsToday.userDefaultsSiteIdKey];
    [sharedDefaults setObject:blogName forKey:AppConfigurationWidgetStatsToday.userDefaultsSiteNameKey];
    [sharedDefaults setObject:blogUrl forKey:AppConfigurationWidgetStatsToday.userDefaultsSiteUrlKey];
    
    NSError *error;
    
    [KeychainUtils.shared storeUsername:AppConfigurationWidgetStats.keychainTokenKey
                               password:oauth2Token
                            serviceName:AppConfigurationWidgetStats.keychainServiceName
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

    [sharedDefaults removeObjectForKey:AppConfigurationWidgetStatsToday.userDefaultsSiteTimeZoneKey];
    [sharedDefaults removeObjectForKey:AppConfigurationWidgetStatsToday.userDefaultsSiteIdKey];
    [sharedDefaults removeObjectForKey:AppConfigurationWidgetStatsToday.userDefaultsSiteNameKey];
    [sharedDefaults removeObjectForKey:AppConfigurationWidgetStatsToday.userDefaultsSiteUrlKey];
    
    [KeychainUtils.shared deleteItemWithUsername:AppConfigurationWidgetStats.keychainTokenKey
                                     serviceName:AppConfigurationWidgetStats.keychainServiceName
                                     accessGroup:WPAppKeychainAccessGroup
                                           error:nil];
}

- (BOOL)widgetIsConfigured
{
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WPAppGroupName];
    NSString *siteId = [sharedDefaults stringForKey:AppConfigurationWidgetStatsToday.userDefaultsSiteIdKey];
    NSString *oauth2Token = [KeychainUtils.shared getPasswordForUsername:AppConfigurationWidgetStats.keychainTokenKey
                                                             serviceName:AppConfigurationWidgetStats.keychainServiceName
                                                             accessGroup:WPAppKeychainAccessGroup
                                                                   error:nil];
    
    if (siteId.length == 0 || oauth2Token.length == 0) {
        return NO;
    } else {
        return YES;
    }
}

@end
