#import "UIApplication+Helpers.h"

@implementation UIApplication (Helpers)

- (BOOL)isRunningTestSuite
{
    Class testSuite = NSClassFromString(@"XCTestCase");
    return testSuite != nil;
}

- (BOOL)isCreatingScreenshots
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"FASTLANE_SNAPSHOT"];
}

@end
