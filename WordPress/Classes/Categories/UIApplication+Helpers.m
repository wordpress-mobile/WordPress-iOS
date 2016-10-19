#import "UIApplication+Helpers.h"



@implementation UIApplication (Helpers)

- (BOOL)isRunningSimulator
{
#if TARGET_IPHONE_SIMULATOR
    return YES;
#endif
    
    return NO;
}

- (BOOL)isRunningTestSuite
{
    Class testSuite = NSClassFromString(@"XCTestCase");
    return testSuite != nil;
}

@end
