#import "UIApplication+Helpers.h"



@implementation UIApplication (Helpers)

- (BOOL)isRunningSimulator
{
#if TARGET_IPHONE_SIMULATOR
    return YES;
#endif
    
    return NO;
}

@end
