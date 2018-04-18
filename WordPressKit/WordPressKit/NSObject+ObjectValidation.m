#import "NSObject+ObjectValidation.h"


@implementation NSObject (ObjectValidation)

- (BOOL)wp_isValidObject
{
    return (self && ![self isEqual:[NSNull null]] && [self isKindOfClass:[NSObject class]]);
}

- (BOOL)wp_isValidString
{
    return ([self wp_isValidObject] && [self isKindOfClass:[NSString class]] && ![(NSString *)self isEqualToString:@""]);
}

@end
