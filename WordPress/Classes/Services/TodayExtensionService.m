#import "TodayExtensionService.h"
#import <NotificationCenter/NotificationCenter.h>
#import "Constants.h"
#import "SFHFKeychainUtils.h"

@implementation TodayExtensionService

- (void)configureTodayWidgetWithSiteID:(NSNumber *)siteID blogName:(NSString *)blogName siteTimeZone:(NSTimeZone *)timeZone andOAuth2Token:(NSString *)oauth2Token
{
    NSParameterAssert(siteID != nil);
    NSParameterAssert(blogName != nil);
    NSParameterAssert(timeZone != nil);
    NSParameterAssert(oauth2Token.length > 0);
    
    if (!WIDGETS_EXIST) {
        return;
    }
    
    [[NCWidgetController widgetController] setHasContent:YES forWidgetWithBundleIdentifier:@"org.wordpress.WordPressTodayWidget"];
    
    // Save the token and site ID to shared user defaults for use in the today widget
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WPAppDefaultsGroupName];
    [sharedDefaults setObject:timeZone.name forKey:WPStatsTodayWidgetUserDefaultsSiteTimeZoneKey];
    [sharedDefaults setObject:siteID forKey:WPStatsTodayWidgetUserDefaultsSiteIdKey];
    [sharedDefaults setObject:blogName forKey:WPStatsTodayWidgetUserDefaultsSiteNameKey];
    [sharedDefaults synchronize];
    
    NSError *error;
    [SFHFKeychainUtils storeUsername:WPAppOAuth2TokenKeychainUsername
                         andPassword:oauth2Token
                      forServiceName:WPAppOAuth2TokenKeychainServiceName
                         accessGroup:WPAppKeychainAccessGroup
                      updateExisting:YES
                               error:&error];
    if (error) {
        DDLogError(@"Today Widget OAuth2Token error: %@", error);
    }
}

- (void)removeTodayWidgetConfiguration
{
    if (!WIDGETS_EXIST) {
        return;
    }
    
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WPAppDefaultsGroupName];
    [sharedDefaults removeObjectForKey:WPStatsTodayWidgetUserDefaultsSiteTimeZoneKey];
    [sharedDefaults removeObjectForKey:WPStatsTodayWidgetUserDefaultsSiteIdKey];
    [sharedDefaults removeObjectForKey:WPStatsTodayWidgetUserDefaultsSiteNameKey];
    [sharedDefaults synchronize];
    
    [SFHFKeychainUtils deleteItemForUsername:WPAppOAuth2TokenKeychainUsername
                              andServiceName:WPAppOAuth2TokenKeychainServiceName
                                 accessGroup:WPAppKeychainAccessGroup
                                       error:nil];
}

- (void)hideTodayWidgetIfNotConfigured
{
    if (!WIDGETS_EXIST) {
        return;
    }
    
    [[NCWidgetController widgetController] setHasContent:YES forWidgetWithBundleIdentifier:@"org.wordpress.WordPressTodayWidget"];
}

- (BOOL)widgetIsConfigured
{
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WPAppDefaultsGroupName];
    NSString *siteId = [sharedDefaults stringForKey:WPStatsTodayWidgetUserDefaultsSiteIdKey];
    NSString *oauth2Token = [SFHFKeychainUtils getPasswordForUsername:WPAppOAuth2TokenKeychainUsername
                                                       andServiceName:WPAppOAuth2TokenKeychainServiceName
                                                          accessGroup:WPAppKeychainAccessGroup
                                                                error:nil];
    
    if (siteId.length == 0 || oauth2Token.length == 0) {
        return NO;
    } else {
        return YES;
    }
}

@end
