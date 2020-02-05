#import "TodayExtensionService.h"
#import <NotificationCenter/NotificationCenter.h>
#import "Constants.h"
#import "SFHFKeychainUtils.h"
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
    NSNumber *previousSiteID = [sharedDefaults objectForKey:WPStatsTodayWidgetUserDefaultsSiteIdKey];
    if (siteID != previousSiteID) {
        [StatsDataHelper clearWidgetsData];
        [WPAnalytics track:WPAnalyticsStatWidgetActiveSiteChanged];
    }

    // Save the site information to shared user defaults for use in the today widgets.
    [sharedDefaults setObject:timeZone.name forKey:WPStatsTodayWidgetUserDefaultsSiteTimeZoneKey];
    [sharedDefaults setObject:siteID forKey:WPStatsTodayWidgetUserDefaultsSiteIdKey];
    [sharedDefaults setObject:blogName forKey:WPStatsTodayWidgetUserDefaultsSiteNameKey];
    [sharedDefaults setObject:blogUrl forKey:WPStatsTodayWidgetUserDefaultsSiteUrlKey];
    
    NSError *error;
    [SFHFKeychainUtils storeUsername:WPStatsTodayWidgetKeychainTokenKey
                         andPassword:oauth2Token
                      forServiceName:WPStatsTodayWidgetKeychainServiceName
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

    [sharedDefaults removeObjectForKey:WPStatsTodayWidgetUserDefaultsSiteTimeZoneKey];
    [sharedDefaults removeObjectForKey:WPStatsTodayWidgetUserDefaultsSiteIdKey];
    [sharedDefaults removeObjectForKey:WPStatsTodayWidgetUserDefaultsSiteNameKey];
    [sharedDefaults removeObjectForKey:WPStatsTodayWidgetUserDefaultsSiteUrlKey];
    
    [SFHFKeychainUtils deleteItemForUsername:WPStatsTodayWidgetKeychainTokenKey
                              andServiceName:WPStatsTodayWidgetKeychainServiceName
                                 accessGroup:WPAppKeychainAccessGroup
                                       error:nil];
}

- (BOOL)widgetIsConfigured
{
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WPAppGroupName];
    NSString *siteId = [sharedDefaults stringForKey:WPStatsTodayWidgetUserDefaultsSiteIdKey];
    NSString *oauth2Token = [SFHFKeychainUtils getPasswordForUsername:WPStatsTodayWidgetKeychainTokenKey
                                                       andServiceName:WPStatsTodayWidgetKeychainServiceName
                                                          accessGroup:WPAppKeychainAccessGroup
                                                                error:nil];
    
    if (siteId.length == 0 || oauth2Token.length == 0) {
        return NO;
    } else {
        return YES;
    }
}

@end
