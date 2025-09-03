#import <UIKit/UIKit.h>

@interface NSString (WPKitHelpers)

- (NSString *)wpkit_stringByUrlEncoding;
- (NSString *)wpkit_stringByStrippingHTML;
- (NSString *)wpkit_stringByEllipsizingWithMaxLength:(NSInteger)lengthlimit preserveWords:(BOOL)preserveWords;
- (bool)wpkit_isEmpty;

@end

@interface NSString (WPKitNumericValueHack)
- (NSNumber *)wpkit_numericValue;
@end

@interface NSObject (WPKitNumericValueHack)
- (NSNumber *)wpkit_numericValue;
@end
