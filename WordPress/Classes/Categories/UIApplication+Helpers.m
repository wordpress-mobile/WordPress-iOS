#import "UIApplication+Helpers.h"



@implementation UIApplication (Helpers)

- (BOOL)isRunningSimulator
{
#if TARGET_IPHONE_SIMULATOR
    return true;
#endif
    
    return false;
}

- (BOOL)isAlphaBuild
{
#if ALPHA_BUILD
    return true;
#endif
    
    return false;
}

@end
