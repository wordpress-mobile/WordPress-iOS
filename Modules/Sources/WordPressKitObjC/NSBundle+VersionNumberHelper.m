#import "NSBundle+VersionNumberHelper.h"

@implementation NSBundle (WPKitVersionNumberHelper)

- (NSString *)wpkit_bundleVersion
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    return infoDictionary[(NSString *)kCFBundleVersionKey] ?: [NSString new];
}

@end
