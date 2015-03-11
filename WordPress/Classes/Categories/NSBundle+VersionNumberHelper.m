#import "NSBundle+VersionNumberHelper.h"

@implementation NSBundle (VersionNumberHelper)

- (NSString *)detailedVersionNumber
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *versionNumberString = [NSString stringWithFormat:@"%@ (%@)", [mainBundle.infoDictionary objectForKey:@"CFBundleShortVersionString"], [mainBundle.infoDictionary objectForKey:@"CFBundleVersion"]];
    return versionNumberString;
}

@end