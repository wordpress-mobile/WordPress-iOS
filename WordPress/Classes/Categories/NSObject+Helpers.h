#import <Foundation/Foundation.h>



@interface NSObject (Helpers)

+ (nonnull NSString *)classNameWithoutNamespaces;

- (void)debounce:(SEL)selector afterDelay:(NSTimeInterval)timeInterval;
@end
