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

- (NSString *)bundleVersion
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    return infoDictionary[(NSString *)kCFBundleVersionKey] ?: [NSString new];
}

@end
