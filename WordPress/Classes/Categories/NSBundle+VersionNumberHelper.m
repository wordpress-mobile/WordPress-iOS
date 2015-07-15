#import "NSBundle+VersionNumberHelper.h"

@implementation NSBundle (VersionNumberHelper)

- (NSString *)detailedVersionNumber
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *versionNumberString = [NSString stringWithFormat:@"%@ (%@)", [mainBundle.infoDictionary objectForKey:@"CFBundleShortVersionString"], [mainBundle.infoDictionary objectForKey:@"CFBundleVersion"]];
    return versionNumberString;
}

- (NSString *)shortVersionString
{
    NSString *appVersion = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleShortVersionString"];
    
#if DEBUG
    appVersion = [appVersion stringByAppendingString:@" (DEV)"];
#endif
    
    return appVersion;
}

@end
