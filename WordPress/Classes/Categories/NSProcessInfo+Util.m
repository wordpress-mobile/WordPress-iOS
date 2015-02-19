#import "NSProcessInfo+Util.h"

@implementation NSProcessInfo (Util)

+ (BOOL)isRunningTests
{
    NSDictionary *environment = [[NSProcessInfo processInfo] environment];
    NSString *injectBundle = environment[@"XCInjectBundle"];
    BOOL result = [[injectBundle pathExtension] isEqualToString:@"xctest"] || [[injectBundle pathExtension] isEqualToString:@"octest"];
    return result;

}

@end
