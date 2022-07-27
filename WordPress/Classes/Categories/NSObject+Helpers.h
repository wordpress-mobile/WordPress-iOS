#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (Helpers)

+ (NSString *)classNameWithoutNamespaces;

- (void)debounce:(SEL)selector afterDelay:(NSTimeInterval)timeInterval;
@end

NS_ASSUME_NONNULL_END
