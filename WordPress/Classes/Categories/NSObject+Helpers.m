#import "NSObject+Helpers.h"



@implementation NSObject (Helpers)

+ (NSString *)classNameWithoutNamespaces
{
    //  Note:
    //  Swift prepends the module name to the class name itself
    return [[NSStringFromClass(self) componentsSeparatedByString:@"."] lastObject];
}

@end
