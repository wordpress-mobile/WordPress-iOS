#import "UIApplication+Helpers.h"

@implementation UIApplication (Helpers)

- (BOOL)isRunningTestSuite
{
    Class testSuite = NSClassFromString(@"XCTestCase");
    return testSuite != nil;
}

@end
