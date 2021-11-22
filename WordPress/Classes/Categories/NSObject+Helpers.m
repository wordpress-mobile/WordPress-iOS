#import "NSObject+Helpers.h"



@implementation NSObject (Helpers)

+ (NSString *)classNameWithoutNamespaces
{
    //  Note:
    //  Swift prepends the module name to the class name itself
    return [[NSStringFromClass(self) componentsSeparatedByString:@"."] lastObject];
}

- (void)debounce:(SEL)selector afterDelay:(NSTimeInterval)timeInterval
{
  __weak __typeof(self) weakSelf = self;
  [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf
                                           selector:selector
                                             object:nil];
  [weakSelf performSelector:selector
                 withObject:nil
                 afterDelay:timeInterval];
}
@end
