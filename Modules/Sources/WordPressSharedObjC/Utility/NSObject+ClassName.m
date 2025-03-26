#import "NSObject+ClassName.h"

@implementation NSObject (ClassName)

+ (NSString *)classNameWithoutNamespaces
{
    // Note that Swift prepends the module name to the class name itself
    return [[NSStringFromClass(self) componentsSeparatedByString:@"."] lastObject];
}

@end
