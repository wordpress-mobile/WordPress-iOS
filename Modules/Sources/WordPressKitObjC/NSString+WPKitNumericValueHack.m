#import "NSString+WPKitNumericValueHack.h"

@implementation NSString (WPKitNumericValueHack)

- (NSNumber *)wpkit_numericValue {
    return [NSNumber numberWithUnsignedLongLong:[self longLongValue]];
}

@end

@implementation NSObject (WPKitNumericValueHack)
- (NSNumber *)wpkit_numericValue {
    if ([self isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)self;
    }
    return nil;
}
@end
