#import "UIApplication+Helpers.h"



@implementation UIApplication (Helpers)

- (BOOL)isRunningSimulator
{
#if TARGET_IPHONE_SIMULATOR
    return YES;
#endif
    
    return NO;
}

- (BOOL)isAlphaBuild
{
#if ALPHA_BUILD
    return YES;
#endif
    
    return NO;
}

@end
