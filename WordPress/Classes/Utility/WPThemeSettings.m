#import "WPThemeSettings.h"

static NSString *WPThemeSettingsUserDefaultsKey = @"WPThemeSettingsUserDefaultsKey";
static NSString *WPThemeSettingsURLScheme = @"themes";
static NSString *WPThemeSettingsURLQueryTurnOff = @"enabled=0";
static NSString *WPThemeSettingsURLQueryTurnOn = @"enabled=1";

@implementation WPThemeSettings

#pragma mark - URL handling

+ (BOOL)handleURL:(NSURL *)url
{
    BOOL result = NO;
    NSString *query = [url query];
    
    if ([query isEqualToString:WPThemeSettingsURLQueryTurnOn]) {
        [self enable];
        result = YES;
    } else if ([query isEqualToString:WPThemeSettingsURLQueryTurnOff]) {
        [self disable];
        result = YES;
    }
    
    return result;
}

+ (BOOL)shouldHandleURL:(NSURL *)url
{
    NSParameterAssert([url isKindOfClass:[NSURL class]]);
    
    return [[url host] isEqualToString:WPThemeSettingsURLScheme];
}

#pragma mark - Enabling and disabling

/**
 *  @brief      Enables the hidden theme feature to be seen by the user.
 */
+ (void)enable
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setBool:YES forKey:WPThemeSettingsUserDefaultsKey];
}

/**
 *  @brief      Disables the hidden theme feature to be seen by the user.
 */
+ (void)disable
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setBool:NO forKey:WPThemeSettingsUserDefaultsKey];
}

+ (BOOL)isEnabled
{
    // IMPORTANT: only debug builds can have this feature for the time being.  It doesn't make
    // sense to make this available in release or internal builds yet.
    //
#ifdef DEBUG
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    return [userDefaults boolForKey:WPThemeSettingsUserDefaultsKey];
#else
    return NO;
#endif
}

@end
